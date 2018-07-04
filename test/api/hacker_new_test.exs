defmodule HackerAggregator.Api.HackerNewsTest do
  use ExUnit.Case
  import Mock

  alias HackerAggregator.Api.ReqWithBackoff, as: Req
  alias HackerAggregator.Api.HackerNews
  alias HackerAggregator.Domain.Story

  test "get top 1 story from hacker news" do
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
      assert {:ok, [story]} = HackerNews.get_top_stories(1)

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

      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/item/8863.json"))
    end
  end

  test "returns error tuple on 404" do
    get_mock = fn _ ->
      {:error, :not_found}
    end

    with_mock Req, get: get_mock do
      assert {:error, :not_found} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
    end
  end

  test "returns error tuple on 500" do
    get_mock = fn _ ->
      {:error, :server_error}
    end

    with_mock Req, get: get_mock do
      assert {:error, :server_error} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
    end
  end

  test "returns error tuple on 500 fetching story" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:error, :server_error}
      end
    end

    with_mock Req, get: get_mock do
      assert {:error, :server_error} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/item/8863.json"))
    end
  end

  test "returns error tuple on timeout fetching top stories" do
    get_mock = fn _ ->
      {:error, :timeout}
    end

    with_mock Req, get: get_mock do
      assert {:error, :timeout} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
    end
  end

  test "returns error tuple on timeout fetching story" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:error, :timeout}
      end
    end

    with_mock Req, get: get_mock do
      assert {:error, :timeout} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/item/8863.json"))
    end
  end

  test "returns error if decoding fails" do
    get_mock = fn uri ->
      cond do
        String.ends_with?(uri, "topstories.json") ->
          {:ok, "[8863]"}

        String.ends_with?(uri, "item/8863.json") ->
          {:ok, "{\"invalid_key\":}"}
      end
    end

    with_mock Req, get: get_mock do
      assert {:error, {:invalid, _, _}} = HackerNews.get_top_stories(1)
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/topstories.json"))
      assert called(Req.get("https://hacker-news.firebaseio.com/v0/item/8863.json"))
    end
  end
end
