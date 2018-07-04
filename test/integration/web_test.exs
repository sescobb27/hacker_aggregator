defmodule HackerAggregator.WebTest do
  use HackerAggregator.ConnCase

  alias HackerAggregator.Aggregator.Background
  alias HackerAggregator.DB.InMemoryDB

  @moduletag :integration

  test "get top stories from hacker news", %{conn: conn} do
    send(Background, {:poll, self()})
    assert_receive :done, 10000

    response =
      conn
      |> get(stories_path(conn, :index))
      |> json_response(200)

    stories = response["stories"]
    assert length(stories) == 10
  end

  test "get story by id", %{conn: conn} do
    send(Background, {:poll, self()})
    assert_receive :done, 10000

    [story] = InMemoryDB.top_stories(1)

    response =
      conn
      |> get(stories_path(conn, :show, story.id))
      |> json_response(200)

    assert response["story"]["id"] == story.id
  end
end
