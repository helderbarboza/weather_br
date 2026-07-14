defmodule WeatherBr.Weather.OpenMeteoTest do
  use ExUnit.Case

  test "fetch_forecasts/2 returns raw temperature lists for given cities" do
    Req.Test.stub(WeatherBr.Weather.OpenMeteo, fn conn ->
      temperatures =
        case {conn.params["latitude"], conn.params["longitude"]} do
          {"10", "20"} -> [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
          {"11", "21"} -> [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
          {"12", "22"} -> [32.0, 32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
        end

      Req.Test.json(conn, %{"daily" => %{"temperature_2m_max" => temperatures}})
    end)

    result =
      WeatherBr.Weather.OpenMeteo.fetch_forecasts([
        {"city_a", 10, 20},
        {"city_b", 11, 21},
        {"city_c", 12, 22}
      ])

    assert length(result) == 3

    [{city_a, temps_a}, {city_b, temps_b}, {city_c, temps_c}] = result
    assert city_a == "city_a"
    assert city_b == "city_b"
    assert city_c == "city_c"

    assert temps_a == [30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
    assert temps_b == [31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
    assert temps_c == [32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
  end
end
