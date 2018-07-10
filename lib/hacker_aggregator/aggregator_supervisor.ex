defmodule HackerAggregator.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      worker(HackerAggregator.DB.InMemoryDB, []),
      worker(HackerAggregator.Aggregator.Background, []),
    ]
    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end
end
