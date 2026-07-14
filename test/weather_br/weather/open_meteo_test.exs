defmodule WeatherBr.Weather.OpenMeteoTest do
  use ExUnit.Case, async: true
  alias WeatherBr.Weather.OpenMeteo

  describe "fetch_forecasts/2" do
    test "returns raw temperature lists for given cities" do
      Req.Test.stub(OpenMeteo, fn conn ->
        temperatures =
          case {conn.params["latitude"], conn.params["longitude"]} do
            {"10", "20"} -> [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
            {"11", "21"} -> [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
            {"12", "22"} -> [32.0, 32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
          end

        Req.Test.json(conn, %{"daily" => %{"temperature_2m_max" => temperatures}})
      end)

      result =
        OpenMeteo.fetch_forecasts([
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

    test "raises when called with an empty list of cities" do
      assert_raise ArgumentError, ~r/cities list must not be empty/, fn ->
        OpenMeteo.fetch_forecasts([])
      end
    end

    test "raises with city context when one city's request fails" do
      Req.Test.stub(OpenMeteo, fn conn ->
        case {conn.params["latitude"], conn.params["longitude"]} do
          {"10", "20"} ->
            Req.Test.json(conn, %{
              "daily" => %{"temperature_2m_max" => [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]}
            })

          _coordinates ->
            Req.Test.json(conn, %{})
        end
      end)

      assert_raise RuntimeError, ~r/(city_b|city_c).*failed/, fn ->
        OpenMeteo.fetch_forecasts([
          {"city_a", 10, 20},
          {"city_b", 11, 21},
          {"city_c", 12, 22}
        ])
      end
    end

    test "raises when called with an invalid number of days" do
      assert_raise ArgumentError, ~r/between 1 and 7/, fn ->
        OpenMeteo.fetch_forecasts([{"city_a", 11, 22}], 0)
      end

      assert_raise ArgumentError, ~r/between 1 and 7/, fn ->
        OpenMeteo.fetch_forecasts([{"city_a", 11, 22}], 8)
      end
    end
  end
end
