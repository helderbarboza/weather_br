defmodule WeatherBr.Weather.OpenMeteo do
  @moduledoc """
  Orchestrates concurrent weather forecast fetching from the Open-Meteo API.

  Delegates HTTP transport and response parsing to
  `WeatherBr.Weather.OpenMeteo.Client`. Retries of transient HTTP errors
  (429, 5xx) and transport errors are handled by Req's built-in
  `:safe_transient` retry step. Non-recoverable errors (400, bad response
  body) fail immediately. Results are returned with partial success —
  successful cities alongside any failures.
  """

  require Logger

  alias WeatherBr.Weather
  alias WeatherBr.Weather.OpenMeteo.Client
  alias WeatherBr.Weather.OpenMeteo.Error

  @type city :: Weather.city()
  @type city_with_temps :: {String.t(), [float()]}
  @type failure :: {String.t(), String.t()}

  @doc """
  Fetches temperature forecasts for multiple cities concurrently.

  Returns `{:ok, successes, failures}` where `successes` is the list of
  successful `{city_name, temperatures}` tuples and `failures` is the
  list of `{city_name, reason}` tuples for cities that failed.
  """
  @spec fetch_forecasts([city()], integer()) :: {:ok, [city_with_temps()], [failure()]}
  def fetch_forecasts(cities, days \\ 6)

  def fetch_forecasts(_cities, days) when days not in 1..7 do
    raise ArgumentError,
          "days must be an integer between 1 and 7 (inclusive), got: #{inspect(days)}"
  end

  def fetch_forecasts([] = cities, _days) do
    raise ArgumentError, "cities list must not be empty, got: #{inspect(cities)}"
  end

  def fetch_forecasts(cities, days) when is_list(cities) and is_integer(days) do
    Logger.info("Fetching forecasts for #{length(cities)} cities, #{days} days ahead")

    cities
    |> Task.async_stream(
      fn {city_name, lat, lon} -> fetch_city_forecast(city_name, lat, lon, days) end,
      max_concurrency: 5,
      timeout: 15_000
    )
    |> Enum.flat_map(fn
      {:ok, {:ok, result}} -> [{:ok, result}]
      {:ok, {:error, error}} -> [{:error, {error.city, Error.message(error)}}]
      {:exit, reason} -> [{:error, {"unknown", "task exited: #{inspect(reason)}"}}]
    end)
    |> collect_results()
  end

  defp fetch_city_forecast(city_name, lat, lon, days) do
    Client.get_forecast(city_name, lat, lon, days)
  end

  defp collect_results(results) do
    {successes, failures} =
      Enum.reduce(results, {[], []}, fn
        {:ok, success}, {succ, fail} -> {[success | succ], fail}
        {:error, failure}, {succ, fail} -> {succ, [failure | fail]}
      end)

    successes = Enum.reverse(successes)
    failures = Enum.reverse(failures)

    Logger.info("Fetched forecasts: #{length(successes)} succeeded, #{length(failures)} failed")

    {:ok, successes, failures}
  end
end
