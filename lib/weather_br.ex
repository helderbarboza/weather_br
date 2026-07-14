defmodule WeatherBr do
  @moduledoc """
  Entrypoint for fetching and presenting weather forecasts.
  """

  alias WeatherBr.Weather

  @spec run() :: String.t()
  def run do
    6
    |> Weather.get_average_temperatures()
    |> format()
  end

  @spec format([{String.t(), Decimal.t()}]) :: String.t()
  def format(results) do
    Enum.map_join(results, "\n", fn {city, temp} -> "#{city}: #{format_temp(temp)}°C" end)
  end

  @spec format_temp(Decimal.t()) :: String.t()
  defp format_temp(temp) do
    temp
    |> Decimal.round(1)
    |> Decimal.to_string()
  end
end
