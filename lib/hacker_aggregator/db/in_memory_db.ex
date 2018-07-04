defmodule HackerAggregator.DB.InMemoryDB do
  use GenServer
  @name __MODULE__
  @table :in_memory_db

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def init(_) do
    :ets.new(@table, [
      :named_table,
      :public,
      read_concurrency: true
    ])
    {:ok, nil}
  end

  def save(stories) do
    mapped_stories =
      Enum.map(stories, fn story ->
        {story.id, story}
      end)
    :ets.insert(@table, mapped_stories)
  end

  def get(story_id) do
    case :ets.lookup(@table, story_id) do
      [] -> nil
      [{^story_id, story}] -> story
    end
  end

  def clear() do
    :ets.delete_all_objects(@table)
  end

  def top_stories(top_n \\ 50) do
    case :ets.match(@table, {:'_', :'$1'}, top_n) do
      :'$end_of_table' -> []
      {results, _} ->
        results
        |> List.flatten()
    end
  end

  # def all(last_id \\ 0)
  # def all() do
  #   :ets.match(@table, '$1', 50)
  # end
  # def all(last_id \\ 0) do
  #   :ets.match(@table, _, 10)
  # end
end
