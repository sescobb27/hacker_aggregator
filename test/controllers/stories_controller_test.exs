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
end
