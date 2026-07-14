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

  @spec get_average_temperatures(integer()) ::
          {:ok, [city_with_avg()], [{String.t(), String.t()}]} | {:error, String.t()}
  def get_average_temperatures(days) do
    case WeatherBr.Weather.OpenMeteo.fetch_forecasts(cities(), days) do
      {:ok, results, failures} ->
        averages =
          Enum.map(results, fn {city_name, temps} ->
            {city_name, average(temps)}
          end)

        {:ok, averages, failures}

      {:error, _reason} = error ->
        error
    end
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
