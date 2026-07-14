defmodule WeatherBr.Weather.OpenMeteo do
  @moduledoc """
  HTTP client wrapper around the Open-Meteo API for fetching
  temperature forecasts for a given set of cities.
  """

  def new(opts \\ []) do
    [
      url: "https://api.open-meteo.com/v1/forecast",
      redirect: true,
      compressed: true
    ]
    |> Keyword.merge(Application.get_env(:weather_br, :http_client_options, []))
    |> Keyword.merge(opts)
    |> Req.new()
  end

  def fetch_forecast(city_name, lat, lon, days \\ 6) do
    req =
      new(
        params: [
          latitude: lat,
          longitude: lon,
          daily: "temperature_2m_max",
          timezone: "America/Sao_Paulo"
        ]
      )

    response = Req.get!(req)
    %{"daily" => %{"temperature_2m_max" => temperatures}} = response.body
    {city_name, Enum.take(temperatures, days)}
  end

  def fetch_forecasts(cities, days \\ 6)

  def fetch_forecasts([] = cities, _days) do
    raise ArgumentError, "cities list must not be empty, got: #{inspect(cities)}"
  end

  def fetch_forecasts(_cities, days) when days not in 1..7 do
    raise ArgumentError,
          "days must be an integer between 1 and 7 (inclusive), got: #{inspect(days)}"
  end

  def fetch_forecasts(cities, days) when is_list(cities) and is_integer(days) do
    cities
    |> Task.async_stream(
      fn {city_name, lat, lon} -> fetch_forecast(city_name, lat, lon, days) end,
      max_concurrency: 5,
      timeout: 10_000
    )
    |> Enum.map(fn {:ok, result} -> result end)
  end
end
