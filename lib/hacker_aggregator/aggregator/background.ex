defmodule HackerAggregator.Aggregator.Background do
  use GenServer
  require Logger

  @name __MODULE__
  @five_minutes 5 * 60 * 1000

  alias HackerAggregator.Api.HackerNews
  alias HackerAggregator.DB.InMemoryDB

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
    case HackerNews.get_top_stories(1) do
      {:error, _error} ->
        # TODO: circuit-breaker after some attempts
        nil

      {:ok, stories} ->
        Logger.info("successfully poll #{length(stories)}")
        InMemoryDB.save(stories)
    end
  end
end
