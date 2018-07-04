defmodule HackerAggregator.DB.InMemoryDB do
  use GenServer
  @name __MODULE__
  @table :in_memory_db

  alias HackerAggregator.Domain.Story

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  # ETS with read concurrency so all request can read the InMermoryDB concurrently and
  # we don't block our Background Aggregator with calls to it, also it is the only one writing to it,
  # so we don't need write concurrency
  def init(_) do
    :ets.new(@table, [
      :named_table,
      :public,
      read_concurrency: true
    ])

    {:ok, nil}
  end

  @spec save(list(Story.t())) :: true
  def save(stories) do
    mapped_stories =
      Enum.map(stories, fn story ->
        {story.id, story}
      end)

    :ets.insert(@table, mapped_stories)
  end

  @spec get(list(Story.id())) :: nil | Story.t()
  def get(story_id) do
    case :ets.lookup(@table, story_id) do
      [] -> nil
      [{^story_id, story}] -> story
    end
  end

  def clear() do
    :ets.delete_all_objects(@table)
  end

  @spec top_stories(top_n :: pos_integer()) :: list(Story.t())
  def top_stories(top_n \\ 50) do
    case :ets.match(@table, {:_, :"$1"}, top_n) do
      :"$end_of_table" ->
        []

      {results, _} ->
        results
        |> List.flatten()
    end
  end

  # paginate over an ETS table using next function, i didn't know how to paginate an ETS table
  # so I tried to do it in the most simple way
  @spec pagination(last_id :: Story.id(), n :: pos_integer()) :: list(Story.t())
  def pagination(last_id, n \\ 10)
  def pagination(0, _), do: top_stories(10)

  def pagination(last_id, n) do
    take(last_id, n)
  end

  defp take(_, 0), do: []

  defp take(last_id, n) do
    case :ets.next(@table, last_id) do
      :"$end_of_table" ->
        []

      story_id ->
        [get(story_id) | take(story_id, n - 1)]
    end
  end
end
