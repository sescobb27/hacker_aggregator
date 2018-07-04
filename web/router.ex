defmodule HackerAggregator.Router do
  use HackerAggregator.Web, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_format, :json)
    plug(:put_secure_browser_headers)
  end

  scope "/api", HackerAggregator do
    pipe_through(:api)
    resources("/stories", StoriesController, only: [:index, :show])
  end
end
