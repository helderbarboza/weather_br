defmodule WeatherBr.Weather.OpenMeteo do
  @moduledoc """
  Orchestrates concurrent weather forecast fetching from the Open-Meteo API.

  Delegates HTTP transport and response parsing to
  `WeatherBr.Weather.OpenMeteo.Client`. Retries of transient HTTP errors
  (429, 5xx) and transport errors are handled by Req's built-in
  `:safe_transient` retry step. Non-recoverable errors (400, bad response
  body) fail immediately.
  """

  alias WeatherBr.Weather
  alias WeatherBr.Weather.OpenMeteo.Client
  alias WeatherBr.Weather.OpenMeteo.Error

  @type city :: Weather.city()
  @type city_with_temps :: {String.t(), [float()]}

  @spec fetch_forecasts([city()], integer()) :: [city_with_temps()]
  def fetch_forecasts(cities, days \\ 6)

  def fetch_forecasts(_cities, days) when days not in 1..7 do
    raise ArgumentError,
          "days must be an integer between 1 and 7 (inclusive), got: #{inspect(days)}"
  end

  def fetch_forecasts([] = cities, _days) do
    raise ArgumentError, "cities list must not be empty, got: #{inspect(cities)}"
  end

  def fetch_forecasts(cities, days) when is_list(cities) and is_integer(days) do
    cities
    |> Task.async_stream(
      fn {city_name, lat, lon} -> fetch_city_forecast(city_name, lat, lon, days) end,
      max_concurrency: 5,
      timeout: 15_000
    )
    |> Enum.map(fn
      {:ok, {:ok, result}} ->
        result

      {:ok, {:error, error}} ->
        raise "forecast for #{error.city} failed: #{Error.message(error)}"

      {:exit, reason} ->
        raise "forecast task failed: #{inspect(reason)}"
    end)
  end

  defp fetch_city_forecast(city_name, lat, lon, days) do
    Client.get_forecast(city_name, lat, lon, days)
  end
end
