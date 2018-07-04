defmodule HackerAggregator.StoryView do
  use HackerAggregator.Web, :view

  def render("index.json", %{stories: stories}) do
    %{stories: stories}
  end

  def render("show.json", %{story: story}) do
    %{story: story}
  end
end
