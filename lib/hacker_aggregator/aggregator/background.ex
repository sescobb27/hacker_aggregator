defmodule HackerAggregator.Aggregator.Background do
  use GenServer
  require Logger

  @name __MODULE__
  @five_minutes 5 * 60 * 1000

  alias HackerAggregator.Api.HackerNews
  alias HackerAggregator.DB.InMemoryDB

  # I'm using a GenServer behind the Application supervisor so if something goes wrong another one
  # can ve spawned also we could have been used its state to manage all the stories as a simple list
  # but I opted for ETS because if we fetch the same stories again and again we will end up with a lot
  # of duplicates so we will end up building something to either merge old and new values or replace
  # old values with new ones which is what ETS does out of the box
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def init(_args) do
    schedule_poll()
    {:ok, nil}
  end

  def handle_info({:poll, listener}, state) do
    fetch_top_stories()
    send(listener, :done)
    {:noreply, state}
  end

  def handle_info(:poll, state) do
    fetch_top_stories()
    schedule_poll()
    {:noreply, state}
  end

  defp schedule_poll() do
    interval = Application.get_env(:hacker_aggregator, :poll_interval, @five_minutes)
    Process.send_after(@name, :poll, interval)
  end

  defp fetch_top_stories() do
    case HackerNews.get_top_stories() do
      {:error, _error} ->
        # TODO: I will add it a circuit-breaker for stopping requests after some :sever_error,
        # :not_found, :timeout errors so we don't keep retrying for a while (fail fast)
        nil

      {:ok, stories} ->
        Logger.info("successfully polled #{length(stories)}")
        InMemoryDB.save(stories)
        broadcast(stories)
    end
  end

  defp broadcast(stories) do
    case HackerAggregator.Endpoint.broadcast("stories", "new_stories", %{stories: stories}) do
      :ok -> :ok
      {:error, error} ->
        Logger.error("error broadcasting channel(stories) event(new_stories) reason: #{inspect error}")
    end
  end
end
