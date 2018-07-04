defmodule HackerAggregator.DB.InMemoryDB do
  use GenServer
  @name __MODULE__
  @table :in_memory_db

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def init(_) do
    :ets.new(@table, [
      :ordered_set,
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
end
