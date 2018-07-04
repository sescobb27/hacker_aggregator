defmodule HackerAggregator.Api.ReqWithBackoff do
  @max_retries 3
  @backoff_factor 1000

  @type error ::
          {:error, :timeout}
          | {:error, :not_found}
          | {:error, :server_error}
          | {:error, HTTPoison.Response.t()}
          | {:error, any()}

  @spec get(uri :: String.t(), tries :: integer()) ::
          {:ok, any()}
          | error()
  def get(uri, tries \\ 0) do
    case HTTPoison.get(uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %HTTPoison.Response{status_code: 500}} ->
        {:error, :server_error}

      {:ok, %HTTPoison.Response{status_code: _} = response} ->
        {:error, response}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        case retry(tries) do
          {:ok, :retry} -> get(uri, tries + 1)
          {:error, :out_of_tries} -> {:error, :timeout}
        end

      {:error, response} ->
        {:error, response}
    end
  end

  @spec retry(tries :: pos_integer) :: {:ok, :retry} | {:error, :out_of_tries}
  defp retry(tries) when tries >= @max_retries, do: {:error, :out_of_tries}

  defp retry(tries) do
    backoff = round(@backoff_factor * :math.pow(2, tries - 1))
    :timer.sleep(backoff)
    {:ok, :retry}
  end
end
