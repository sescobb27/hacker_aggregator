defmodule HackerAggregator.StoriesControllerTest do
  use HackerAggregator.ConnCase

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

    true = InMemoryDB.save(stories)
    :ok
  end

  describe "show story" do
    test "gets an already saved story", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :show, "8864"))
        |> json_response(200)

      story = response["story"]
      assert story["id"] == 8864

      assert %{
               "id" => 8864,
               "title" => "Story 2",
               "type" => "story",
               "url" => "story2.com"
             } = story
    end

    test "returns an error when trying to fetch a story that doesn't exist", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :show, "1"))
        |> json_response(404)

      assert response == %{"errors" => %{"detail" => "Page not found"}}
    end

    test "returns an error when invalid id", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :show, "1"))
        |> json_response(404)

      assert response == %{"errors" => %{"detail" => "Page not found"}}
    end
  end

  describe "pagination over stories" do
    setup do
      true =
        1..20
        |> Enum.map(fn num ->
          %Story{
            id: 8864 + num,
            title: "Story #{num}",
            type: "story",
            url: "story#{num}.com"
          }
        end)
        |> InMemoryDB.save()

      :ok
    end

    test "gets initial stories", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :index))
        |> json_response(200)

      stories = response["stories"]
      assert length(stories) == 10
    end

    test "gets stories from last story", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :index))
        |> json_response(200)

      stories = response["stories"]
      last_story = List.last(stories)

      response2 =
        conn
        |> get(stories_path(conn, :index, %{"from" => last_story["id"]}))
        |> json_response(200)

      stories2 = response2["stories"]
      assert length(stories2) == 10
      assert stories != stories2
    end

    test "fails if invalid story id", %{conn: conn} do
      response =
        conn
        |> get(stories_path(conn, :index, %{"from" => "invalid"}))
        |> json_response(404)

      assert response == %{"errors" => %{"detail" => "Page not found"}}
    end
  end
end
