defmodule HackerAggregator.StoriesChannel do
  use HackerAggregator.Web, :channel

  alias HackerAggregator.DB.InMemoryDB

  def join("stories", _params, socket) do
    stories = InMemoryDB.top_stories()
    {:ok, %{stories: stories}, socket}
  end
end
