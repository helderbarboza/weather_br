defmodule WeatherBr.Weather do
  @doc false
  defp cities do
    [
      {"São Paulo", -23.55, -46.63},
      {"Belo Horizonte", -19.92, -43.94},
      {"Curitiba", -25.43, -49.27}
    ]
  end

  def get_temperatures do
    WeatherBr.Weather.OpenMeteo.get_temperatures(cities())
  end
end
