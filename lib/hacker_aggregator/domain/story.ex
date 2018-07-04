defmodule HackerAggregator.Domain.Story do

  @type id :: String.t()
  @type poll :: id()
  @type story_type :: :job | :story | :comment | :poll | :pollopt

  @type t :: %__MODULE__{
    id: id(),
    deleted: boolean(),
    type: story_type(),
    by: String.t(),
    time: pos_integer(),
    text: String.t(),
    dead: boolean(),
    parent: id() | nil,
    poll: poll(),
    kids: list(id()),
    url: String.t(),
    score: pos_integer(),
    title: String.t(),
    parts: list(poll()),
    descendants: pos_integer()
  }

  defstruct [
    :id,
    :type,
    :by,
    :time,
    :text,
    :parent,
    :poll,
    :url,
    :score,
    :title,
    :descendants,
    kids: [],
    parts: [],
    deleted: false,
    dead: false
  ]

  @spec new(attrs :: Keyword.t() | Map.t()) :: t()
  def new(attrs \\ []) do
    struct!(__MODULE__, attrs)
  end
end
