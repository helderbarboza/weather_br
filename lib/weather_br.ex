defmodule WeatherBr do
  @moduledoc """
  Entrypoint for fetching and presenting weather forecasts.
  """

  alias WeatherBr.Weather

  def run do
    6
    |> Weather.get_average_temperatures()
    |> format()
  end

  def format(results) do
    Enum.map_join(results, "\n", fn {city, temp} -> "#{city}: #{format_temp(temp)}°C" end)
  end

  defp format_temp(temp) do
    temp
    |> Decimal.round(1)
    |> Decimal.to_string()
  end
end
