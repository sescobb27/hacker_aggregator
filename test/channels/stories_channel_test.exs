defmodule HackerAggregator.StoriesChannelTest do
  use HackerAggregator.ChannelCase

  alias HackerAggregator.StoriesChannel
  alias HackerAggregator.Domain.Story
  alias HackerAggregator.DB.InMemoryDB
  alias HackerAggregator.Api.ReqWithBackoff, as: Req
  alias HackerAggregator.Aggregator.Background

  import Mock

  setup do
    true =
      1..50
      |> Enum.map(fn num ->
        %Story{
          id: 8864 + num,
          title: "Story #{num}",
          type: "story",
          url: "story#{num}.com"
        }
      end)
      |> InMemoryDB.save()

    on_exit(fn ->
      InMemoryDB.clear()
    end)

    :ok
  end

  test "gets top 50 places when connection is stablished" do
    {:ok, %{stories: stories}, _} =
      socket()
      |> subscribe_and_join(StoriesChannel, "stories", %{})

    assert length(stories) == 50
  end

  test "gets new stories when successfully polling for more stories" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:ok,
           "{\"url\":\"http://www.getdropbox.com/u/2/screencast.html\",\"type\":\"story\",\"title\":\"My YC app: Dropbox - Throw away your USB drive\",\"time\":1175714200,\"score\":111,\"kids\":[],\"id\":8863,\"descendants\":71,\"by\":\"dhouston\"}"}
      end
    end

    {:ok, _, _} =
      socket()
      |> subscribe_and_join(StoriesChannel, "stories", %{})

    with_mock Req, get: get_mock do
      send(Background, {:poll, self()})
      assert_receive :done, 1000
      assert_broadcast("new_stories", %{stories: stories}, 1000)

      assert [story] = stories

      assert %Story{
               by: "dhouston",
               dead: false,
               deleted: false,
               descendants: 71,
               id: 8863,
               parent: nil,
               parts: [],
               poll: nil,
               score: 111,
               text: nil,
               time: 1_175_714_200,
               title: "My YC app: Dropbox - Throw away your USB drive",
               type: "story",
               url: "http://www.getdropbox.com/u/2/screencast.html"
             } = story
    end
  end
end
