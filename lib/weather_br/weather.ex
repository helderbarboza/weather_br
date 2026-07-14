defmodule WeatherBr.Weather do
  @moduledoc """
  Public API facade for fetching and processing weather data.
  """

  @type city :: {String.t(), float(), float()}
  @type city_with_avg :: {String.t(), Decimal.t()}

  @cities [
    {"São Paulo", -23.55, -46.63},
    {"Belo Horizonte", -19.92, -43.94},
    {"Curitiba", -25.43, -49.27}
  ]

  @doc false
  @spec cities() :: [city()]
  def cities, do: @cities

  @spec get_average_temperatures(integer()) :: [city_with_avg()]
  def get_average_temperatures(days) do
    cities()
    |> WeatherBr.Weather.OpenMeteo.fetch_forecasts(days)
    |> Enum.map(fn {city_name, temps} -> {city_name, average(temps)} end)
  end

  @doc false
  @spec average([float()]) :: Decimal.t()
  def average(numbers) when is_list(numbers) and numbers !== [] do
    length = Enum.count(numbers)

    numbers
    |> Enum.map(&Decimal.from_float/1)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
    |> Decimal.div(length)
  end
end
