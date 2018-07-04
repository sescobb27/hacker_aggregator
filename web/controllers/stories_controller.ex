defmodule HackerAggregator.StoriesController do
  use HackerAggregator.Web, :controller

  alias HackerAggregator.DB.InMemoryDB

  # we are using "from" query param to fetch 10 stories from the last one seen, it may not be the best
  # pagination system but i couldn't figure it out how to paginate properly over ETS without converting
  # all the table into a list and paginate it (but is the same as the pagination system from Stripe)
  def index(conn, params) do
    try do
      stories =
        Map.get(params, "from", "0")
        |> String.to_integer()
        |> InMemoryDB.pagination()

      conn
      |> put_status(:ok)
      |> render(HackerAggregator.StoryView, "index.json", stories: stories)
    rescue
      ArgumentError ->
        conn
        |> put_status(:not_found)
        |> render(HackerAggregator.ErrorView, "404.json")
        |> halt()
    end
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
