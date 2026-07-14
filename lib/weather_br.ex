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

  @spec format({:ok, [{String.t(), Decimal.t()}], [{String.t(), String.t()}]}) :: String.t()
  def format({:ok, results, failures}) do
    successes =
      Enum.map_join(results, "\n", fn {city, temp} -> "#{city}: #{format_temp(temp)}°C" end)

    errors = format_failures(failures)

    [successes, errors]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp format_failures([]), do: ""

  defp format_failures(failures) do
    lines = Enum.map(failures, fn {city, reason} -> "  #{city}: #{reason}" end)
    "Failed cities:\n" <> Enum.join(lines, "\n")
  end

  @spec format_temp(Decimal.t()) :: String.t()
  defp format_temp(temp) do
    temp
    |> Decimal.round(1)
    |> Decimal.to_string()
  end
end
