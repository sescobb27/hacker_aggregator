defmodule HackerAggregator.Aggregator.InMemoryDBTest do
  use ExUnit.Case

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

    on_exit(fn ->
      InMemoryDB.clear()
    end)

    {:ok, stories: stories}
  end

  test "stores a list of stories", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    stories = :ets.tab2list(:in_memory_db)
    assert length(stories) == 2

    story_ids =
      Enum.map(stories, fn {id, _} ->
        id
      end)

    assert Enum.member?(story_ids, 8863)
    assert Enum.member?(story_ids, 8864)
  end

  test "gets an story from previously saved stories", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    story1 = InMemoryDB.get(8863)
    assert %Story{} = story1
    story = hd(stories)
    assert story == story1
  end

  test "get top stories - more than available", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    top_stories = InMemoryDB.top_stories()
    assert length(top_stories) == 2
    story_ids = Enum.map(top_stories, & &1.id)

    assert Enum.member?(story_ids, 8863)
    assert Enum.member?(story_ids, 8864)
  end

  test "get top stories - less than available", %{stories: stories} do
    assert true = InMemoryDB.save(stories)
    top_stories = InMemoryDB.top_stories(1)
    assert length(top_stories) == 1
  end
end
