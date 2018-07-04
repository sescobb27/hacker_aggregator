defmodule HackerAggregator.Domain.StoryTest do
  use ExUnit.Case, async: true

  alias HackerAggregator.Domain.Story

  test "creates an empty story" do
    assert %Story{} = Story.new()
  end

  test "creates a story with attrs" do
    assert %Story{id: 1} = Story.new(id: 1)
  end
end
