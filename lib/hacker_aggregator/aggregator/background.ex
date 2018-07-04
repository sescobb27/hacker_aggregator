defmodule HackerAggregator.Aggregator.Background do
  use GenServer
  require Logger

  @name __MODULE__
  @five_minutes 5 * 60 * 1000

  alias HackerAggregator.Api.HackerNews

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def init(_args) do
    schedule_poll()
    {:ok, []}
  end

  def get_top_stories() do
    GenServer.call(@name, :get_top_stories)
  end

  def handle_call(:get_top_stories, _from, state) do
    # TODO: add better pagination
    {:reply, Enum.take(state, 10), state}
  end

  def handle_info(:poll, state) do
    new_state =
      case HackerNews.get_top_stories(1) do
        {:error, _error} ->
          # TODO: circuit-breaker after some attempts
          state

        {:ok, stories} ->
          # TODO: store stories on ETS
          Logger.info("successfully poll #{length(stories)} #{inspect(stories)}")

          state
          |> Enum.concat(stories)
          |> Enum.uniq_by(fn story ->
            story.id
          end)
      end

    schedule_poll()
    {:noreply, new_state}
  end

  defp schedule_poll() do
    interval = Application.get_env(:hacker_aggregator, :poll_interval, @five_minutes)
    Process.send_after(@name, :poll, interval)
  end
end
