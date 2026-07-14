defmodule WeatherBr.Weather.OpenMeteo.Client do
  @moduledoc """
  Low-level HTTP client for the Open-Meteo API.

  Handles request construction, HTTP transport, response parsing,
  and error mapping. Does not concern itself with concurrency or
  partial-success collection — that is the responsibility of
  `WeatherBr.Weather.OpenMeteo`.
  """

  alias WeatherBr.Weather.OpenMeteo.Error

  @type city_name :: String.t()
  @type temperatures :: [float()]

  @spec new(keyword()) :: Req.Request.t()
  def new(opts \\ []) do
    {cachex_opts, opts} =
      opts
      |> Keyword.merge(Application.get_env(:weather_br, :http_client_options, []))
      |> Keyword.pop(:cachex, :default)

    [
      url: "https://api.open-meteo.com/v1/forecast",
      redirect: true,
      compressed: true
    ]
    |> Keyword.merge(opts)
    |> Req.new()
    |> maybe_attach_cache(cachex_opts)
  end

  @doc """
  Calls the Open-Meteo forecast endpoint for a single city.

  Returns `{:ok, {city_name, temperatures}}` on success, or
  `{:error, Error.t()}` on any failure (bad request, rate limit,
  server error, transport error, malformed response).
  """
  @spec get_forecast(city_name(), float(), float(), pos_integer()) ::
          {:ok, {city_name(), temperatures()}} | {:error, Error.t()}
  def get_forecast(city_name, lat, lon, days) do
    req =
      new(
        params: [
          latitude: lat,
          longitude: lon,
          daily: "temperature_2m_max",
          timezone: "America/Sao_Paulo"
        ]
      )

    case Req.get(req) do
      {:ok, %{status: 200, body: body}} ->
        handle_ok_response(body, city_name, days)

      {:ok, response} ->
        {:error, response_to_error(response, city_name)}

      {:error, exception} ->
        {:error,
         Error.new(type: :http, city: city_name, reason: "request failed: #{inspect(exception)}")}
    end
  end

  defp handle_ok_response(body, city_name, days) do
    case body do
      %{"daily" => %{"temperature_2m_max" => temperatures}} when is_list(temperatures) ->
        {:ok, {city_name, Enum.take(temperatures, days)}}

      %{"error" => true, "reason" => reason} ->
        {:error, Error.new(type: :api, status: 200, city: city_name, reason: reason)}

      other ->
        {:error,
         Error.new(
           type: :parse,
           status: 200,
           city: city_name,
           reason: "unexpected response body: #{inspect(other)}"
         )}
    end
  end

  defp response_to_error(%{status: 400, body: body}, city_name) do
    Error.new(type: :api, status: 400, city: city_name, reason: extract_reason(body))
  end

  defp response_to_error(%{status: 429, body: body}, city_name) do
    Error.new(type: :api, status: 429, city: city_name, reason: extract_reason(body))
  end

  defp response_to_error(%{status: status, body: body}, city_name) when status >= 500 do
    Error.new(
      type: :api,
      status: status,
      city: city_name,
      reason: extract_reason(body) || "internal server error"
    )
  end

  defp response_to_error(%{status: status}, city_name) do
    Error.new(type: :api, status: status, city: city_name, reason: "unexpected HTTP #{status}")
  end

  defp extract_reason(body) when is_map(body), do: Map.get(body, "reason")
  defp extract_reason(_body), do: nil

  defp maybe_attach_cache(req, false), do: req

  defp maybe_attach_cache(req, :default),
    do: WeatherBr.Req.CachexStep.attach(req, cache: :weather_cache, ttl: :timer.minutes(5))

  defp maybe_attach_cache(req, opts), do: WeatherBr.Req.CachexStep.attach(req, opts)
end
