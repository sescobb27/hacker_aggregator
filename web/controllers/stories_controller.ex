defmodule HackerAggregator.StoriesController do
  use HackerAggregator.Web, :controller

  alias HackerAggregator.DB.InMemoryDB

  def index(conn, params) do
    page = Map.get(params, "page", 0)
  end

  def show(conn, %{"id" => story_id}) do
    try do
      story_id = String.to_integer(story_id)

      case InMemoryDB.get(story_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> render(HackerAggregator.ErrorView, "404.json")
          |> halt()

        story ->
          conn
          |> put_status(:ok)
          |> render(HackerAggregator.StoryView, "show.json", story: story)
      end
    rescue
      ArgumentError ->
        conn
        |> put_status(:not_found)
        |> render(HackerAggregator.ErrorView, "404.json")
        |> halt()
      end
  end
end