defmodule WeatherBr.Weather.OpenMeteoTest do
  use ExUnit.Case
  import Plug.Conn

  test "get_temperatures/1 returns average temperatures" do
    Req.Test.stub(WeatherBr.Weather.OpenMeteo, fn conn ->
      temperatures =
        case {conn.params["latitude"], conn.params["longitude"]} do
          {"10", "20"} -> [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
          {"11", "21"} -> [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
          {"12", "22"} -> [32.0, 32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
        end

      conn
      |> put_resp_content_type("application/json")
      |> resp(200, Jason.encode!(%{"daily" => %{"temperature_2m_max" => temperatures}}))
    end)

    result =
      WeatherBr.Weather.OpenMeteo.get_temperatures([
        {"city_a", 10, 20},
        {"city_b", 11, 21},
        {"city_c", 12, 22}
      ])

    [{city_a, temp_a}, {city_b, temp_b}, {city_c, temp_c}] = result
    assert city_a == "city_a"
    assert city_b == "city_b"
    assert city_c == "city_c"

    assert Decimal.compare(temp_a, Decimal.new("30")) == :eq
    assert Decimal.compare(temp_b, Decimal.new("31")) == :eq
    assert Decimal.compare(temp_c, Decimal.new("32")) == :eq
  end
end
