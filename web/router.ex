defmodule HackerAggregator.Router do
  use HackerAggregator.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", HackerAggregator do
    pipe_through :api
  end
end
