defmodule HackerAggregator.Api.ReqWithBackoffTest do
  use ExUnit.Case, async: true
  import Mock

  alias HackerAggregator.Api.ReqWithBackoff, as: Req

  test "returns body if 200" do
    get_mock = fn _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: "Test Body"}}
    end

    with_mock HTTPoison, get: get_mock do
      assert {:ok, "Test Body"} = Req.get("url.com")
    end
  end

  test "fails with :not_found if 404" do
    get_mock = fn _ ->
      {:ok, %HTTPoison.Response{status_code: 404, body: "Test Body"}}
    end

    with_mock HTTPoison, get: get_mock do
      assert {:error, :not_found} = Req.get("url.com")
    end
  end

  test "fails with :timeout if request timeout" do
    get_mock = fn _ ->
      {:error, %HTTPoison.Error{reason: :timeout}}
    end

    with_mock HTTPoison, get: get_mock do
      assert {:error, :timeout} = Req.get("url.com", 2)
    end
  end
end
