defmodule HackerAggregator.Aggregator.BackgroundTest do
  use ExUnit.Case

  import Mock

  alias HackerAggregator.Aggregator.Background
  alias HackerAggregator.Domain.Story
  alias HackerAggregator.Api.ReqWithBackoff, as: Req
  alias HackerAggregator.DB.InMemoryDB

  setup do
    on_exit(fn ->
      InMemoryDB.clear()
    end)
  end

  test "gets top stories from hacker news" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:ok,
           "{\"url\":\"http://www.getdropbox.com/u/2/screencast.html\",\"type\":\"story\",\"title\":\"My YC app: Dropbox - Throw away your USB drive\",\"time\":1175714200,\"score\":111,\"kids\":[],\"id\":8863,\"descendants\":71,\"by\":\"dhouston\"}"}
      end
    end

    with_mock Req, get: get_mock do
      send(Background, {:poll, self()})
      assert_receive :done, 1000
      assert [story] = InMemoryDB.top_stories()

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

  test "returns current stories on error fetching top stories" do
    get_mock = fn _ ->
      {:error, :server_error}
    end

    with_mock Req, get: get_mock do
      send(Background, {:poll, self()})
      assert_receive :done, 1000
      assert [] = InMemoryDB.top_stories()
    end
  end

  test "returns current stories on error fetching stories" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:error, :server_error}
      end
    end

    with_mock Req, get: get_mock do
      send(Background, {:poll, self()})
      assert_receive :done, 1000
      assert [] = InMemoryDB.top_stories()
    end
  end
end
