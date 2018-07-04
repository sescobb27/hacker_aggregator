defmodule HackerAggregator.Api.HackerNews do
  alias HackerAggregator.Domain.Story
  alias HackerAggregator.Api.ReqWithBackoff, as: Req

  @hacker_news_base_url "https://hacker-news.firebaseio.com"
  @api_version "v0"
  @top_stories_endpoint "topstories.json"
  @items_endpoint "item"

  @type decode_error :: {:error, :invalid} | {:error, {:invalid, String.t(), pos_integer()}}

  @spec get_top_stories() ::
          {:ok, list(Story.t())}
          | Req.error()
          | {:error, :invalid}
          | {:error, {:invalid, String.t()}}
          | {:error, any()}
  def get_top_stories(top_n \\ 50) do
    do_get_top_stories_ids()
    |> maybe_decode()
    |> maybe_take(top_n)
    |> maybe_do_get_top_stories()
  end

  defp do_get_top_stories_ids() do
    [
      @hacker_news_base_url,
      @api_version,
      @top_stories_endpoint
    ]
    |> Enum.join("/")
    |> Req.get()
  end

  @spec do_get_story(id :: Story.id()) ::
          {:ok, String.t()} | {:error, :timeout | :not_found | :server_error | any()}
  defp do_get_story(id) do
    [
      @hacker_news_base_url,
      @api_version,
      @items_endpoint,
      "#{id}.json"
    ]
    |> Enum.join("/")
    |> Req.get()
  end

  @spec maybe_decode({:ok, any()} | Req.error(), opts :: Keyword.t()) ::
          {:ok, Poison.Parser.t()}
          | decode_error()
  defp maybe_decode(body_or_error, opts \\ [])
  defp maybe_decode({:error, _} = error, _), do: error
  defp maybe_decode({:ok, body}, opts), do: Poison.decode(body, opts)

  @spec maybe_take({:ok, list(any())} | Req.error() | decode_error(), top_n :: pos_integer()) ::
          {:ok, list(any)} | Req.error() | decode_error()
  defp maybe_take({:error, _} = error, _), do: error

  defp maybe_take({:ok, results}, top_n) do
    {:ok, Enum.take(results, top_n)}
  end

  @spec maybe_do_get_top_stories({:ok, list(Story.id())} | Req.error() | decode_error()) ::
          {:ok, list(Story.t())} | Req.error() | decode_error()
  defp maybe_do_get_top_stories({:error, _} = error), do: error

  defp maybe_do_get_top_stories({:ok, top_n_story_ids}) do
    maybe_stories =
      top_n_story_ids
      |> Enum.map(fn story_id ->
        maybe_get_story(story_id)
      end)

    stories = for {:ok, story} <- maybe_stories, do: story

    if Enum.empty?(stories) do
      errors = for {:error, error} <- maybe_stories, do: error
      more_ocurred_error(errors)
    else
      {:ok, stories}
    end
  end

  @spec maybe_get_story(Story.id()) :: {:ok, list(Story.t())} | Req.error() | decode_error()
  defp maybe_get_story(story_id) do
    do_get_story(story_id)
    |> maybe_decode(as: %Story{})
  end

  @spec more_ocurred_error(errors :: list()) :: Req.error() | decode_error()
  defp more_ocurred_error(errors) do
    {error, _} =
      Enum.reduce(errors, %{}, fn error, acc ->
        {_, new_acc} =
          Map.get_and_update(acc, error, fn
            nil -> {nil, 1}
            value -> {value, value + 1}
          end)

        new_acc
      end)
      |> Map.to_list()
      |> Enum.max_by(fn {_, value} ->
        value
      end)

    {:error, error}
  end
end
