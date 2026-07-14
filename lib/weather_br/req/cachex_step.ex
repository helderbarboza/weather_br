defmodule WeatherBr.Req.CachexStep do
  @moduledoc """
  A Req step plugin that caches HTTP responses in Cachex.

  ## Usage

      iex> Req.new()
      ...> |> WeatherBr.Req.CachexStep.attach(cache: :my_cache, ttl: :timer.minutes(5))
      ...> |> Req.get!()

  Options:

    * `:cache` - the Cachex cache name (default `:weather_cache`)
    * `:ttl` - time-to-live in milliseconds (default `:timer.minutes(30)`)
  """

  @default_cache :weather_cache
  @default_ttl :timer.minutes(30)

  @doc false
  @spec attach(Req.Request.t(), keyword()) :: Req.Request.t()
  def attach(request, opts \\ []) do
    request
    |> Req.Request.put_private(:cachex_cache, Keyword.get(opts, :cache, @default_cache))
    |> Req.Request.put_private(:cachex_ttl, Keyword.get(opts, :ttl, @default_ttl))
    |> Req.Request.append_request_steps(cachex: &check_cache/1)
    |> Req.Request.prepend_response_steps(cachex: &store_cache/1)
  end

  defp check_cache(request) do
    cache = Req.Request.get_private(request, :cachex_cache)
    key = cache_key(request)

    case Cachex.get(cache, key) do
      {:ok, nil} -> request
      {:ok, response} -> {request, response}
      _entry -> request
    end
  end

  defp store_cache({request, response}) do
    cache = Req.Request.get_private(request, :cachex_cache)
    ttl = Req.Request.get_private(request, :cachex_ttl)
    key = cache_key(request)

    Cachex.put(cache, key, response, ttl: ttl)
    {request, response}
  end

  defp cache_key(request) do
    :sha256
    |> :crypto.hash("#{request.method}:#{request.url}")
    |> Base.encode16()
  end
end
