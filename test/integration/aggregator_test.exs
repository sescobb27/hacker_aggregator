defmodule HackerAggregator.AggregatorTest do
  use HackerAggregator.ChannelCase

  alias HackerAggregator.Aggregator.Background
  alias HackerAggregator.StoriesChannel
  alias HackerAggregator.DB.InMemoryDB

  @moduletag :integration

  test "get top stories from hacker news" do
    {:ok, _, _} =
      socket()
      |> subscribe_and_join(StoriesChannel, "stories", %{})

    send(Background, {:poll, self()})
    assert_receive :done, 10000
    db_stories = InMemoryDB.top_stories()
    refute Enum.empty?(db_stories)
    assert_broadcast("new_stories", %{stories: stories}, 1000)
    refute Enum.empty?(stories)
  end
end
