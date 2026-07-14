defmodule WeatherBr.WeatherTest do
  use ExUnit.Case

  test "get_average_temperatures/0 returns average temperatures for hardcoded cities" do
    Req.Test.stub(WeatherBr.Weather.OpenMeteo, fn conn ->
      temperatures =
        case {conn.params["latitude"], conn.params["longitude"]} do
          # São Paulo
          {"-23.55", "-46.63"} -> [28.0, 30.0, 32.0, 29.0, 31.0, 33.0, 30.0]
          # Belo Horizonte
          {"-19.92", "-43.94"} -> [35.0, 36.0, 34.0, 37.0, 35.0, 36.0, 35.0]
          # Curitiba
          {"-25.43", "-49.27"} -> [22.0, 24.0, 23.0, 21.0, 25.0, 26.0, 24.0]
        end

      Req.Test.json(conn, %{"daily" => %{"temperature_2m_max" => temperatures}})
    end)

    result = WeatherBr.Weather.get_average_temperatures()
    assert length(result) == 3

    temps = Map.new(result)

    assert Decimal.compare(temps["São Paulo"], Decimal.new("30.5")) == :eq
    assert Decimal.compare(temps["Belo Horizonte"], Decimal.new("35.5")) == :eq
    assert Decimal.compare(temps["Curitiba"], Decimal.new("23.5")) == :eq
  end
end
