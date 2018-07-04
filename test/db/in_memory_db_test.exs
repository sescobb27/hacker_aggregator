defmodule HackerAggregator.Aggregator.BackgroundTest do
  use ExUnit.Case

  import Mock

  alias HackerAggregator.Domain.Story
  alias HackerAggregator.DB.InMemoryDB

  setup do
    stories = [
      %Story{
        id: 8863,
        title: "Story 1",
        type: "story",
        url: "story1.com"
      },
      %Story{
        id: 8864,
        title: "Story 2",
        type: "story",
        url: "story2.com"
      }
    ]

    {:ok, stories: stories}
  end

  test "stores a list of stories", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    stories = :ets.tab2list(:in_memory_db)
    assert length(stories) == 2
    assert [{8863, _}, {8864, _}] = stories
  end

  test "gets an story from previously saved stories", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    story1 = InMemoryDB.get(8863)
    assert %Story{} = story1
    story = hd(stories)
    assert story == story1
  end
end
