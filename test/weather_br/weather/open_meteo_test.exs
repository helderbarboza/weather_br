defmodule WeatherBr.Weather.OpenMeteoTest do
  use ExUnit.Case, async: true
  alias WeatherBr.Weather.OpenMeteo
  alias WeatherBr.Weather.OpenMeteo.Client

  describe "fetch_forecasts/2" do
    test "returns raw temperature lists for given cities" do
      Req.Test.stub(Client, fn conn ->
        temperatures =
          case {conn.params["latitude"], conn.params["longitude"]} do
            {"10", "20"} -> [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
            {"11", "21"} -> [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
            {"12", "22"} -> [32.0, 32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
          end

        Req.Test.json(conn, %{"daily" => %{"temperature_2m_max" => temperatures}})
      end)

      assert {:ok, results, []} =
               OpenMeteo.fetch_forecasts([
                 {"city_a", 10, 20},
                 {"city_b", 11, 21},
                 {"city_c", 12, 22}
               ])

      assert length(results) == 3

      [{city_a, temps_a}, {city_b, temps_b}, {city_c, temps_c}] = results
      assert city_a == "city_a"
      assert city_b == "city_b"
      assert city_c == "city_c"

      assert temps_a == [30.0, 30.0, 30.0, 30.0, 30.0, 30.0]
      assert temps_b == [31.0, 31.0, 31.0, 31.0, 31.0, 31.0]
      assert temps_c == [32.0, 32.0, 32.0, 32.0, 32.0, 32.0]
    end

    test "respects the days parameter" do
      Req.Test.stub(Client, fn conn ->
        Req.Test.json(conn, %{
          "daily" => %{"temperature_2m_max" => [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]}
        })
      end)

      assert {:ok, [{"city_a", temps}], []} = OpenMeteo.fetch_forecasts([{"city_a", 10, 20}], 3)
      assert length(temps) == 3
    end

    test "raises when called with an empty list of cities" do
      assert_raise ArgumentError, ~r/cities list must not be empty/, fn ->
        OpenMeteo.fetch_forecasts([])
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

    test "returns failure on 400 Bad Request with API reason" do
      Req.Test.stub(Client, fn conn ->
        conn
        |> Plug.Conn.put_status(400)
        |> Req.Test.json(%{"error" => true, "reason" => "Invalid latitude"})
      end)

      assert {:ok, [], [{"city_a", reason}]} = OpenMeteo.fetch_forecasts([{"city_a", 999, 999}])
      assert reason =~ "API error for city_a"
      assert reason =~ "Invalid latitude"
    end

    test "returns failure on 429 Too Many Requests" do
      Req.Test.stub(Client, fn conn ->
        conn
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"error" => true, "reason" => "Hourly API request limit exceeded"})
      end)

      assert {:ok, [], [{"city_a", reason}]} = OpenMeteo.fetch_forecasts([{"city_a", 10, 20}])
      assert reason =~ "API error"
      assert reason =~ "Hourly API request limit exceeded"
    end

    test "returns failure on 500 Internal Server Error" do
      Req.Test.stub(Client, fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{"reason" => "database timeout"})
      end)

      assert {:ok, [], [{"city_a", reason}]} = OpenMeteo.fetch_forecasts([{"city_a", 10, 20}])
      assert reason =~ "API error"
      assert reason =~ "database timeout"
    end

    test "returns failure on malformed response body" do
      Req.Test.stub(Client, fn conn ->
        Req.Test.json(conn, %{"unexpected" => "data"})
      end)

      assert {:ok, [], [{"city_a", reason}]} = OpenMeteo.fetch_forecasts([{"city_a", 10, 20}])
      assert reason =~ "unexpected response body"
    end

    test "returns partial results when some cities fail" do
      Req.Test.stub(Client, fn conn ->
        case {conn.params["latitude"], conn.params["longitude"]} do
          {"10", "20"} ->
            Req.Test.json(conn, %{
              "daily" => %{"temperature_2m_max" => [30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0]}
            })

          {"11", "21"} ->
            conn
            |> Plug.Conn.put_status(400)
            |> Req.Test.json(%{"error" => true, "reason" => "bad coords"})

          {"12", "22"} ->
            Req.Test.json(conn, %{
              "daily" => %{"temperature_2m_max" => [32.0, 32.0, 32.0, 32.0, 32.0, 32.0, 32.0]}
            })
        end
      end)

      assert {:ok, results, failures} =
               OpenMeteo.fetch_forecasts([
                 {"city_a", 10, 20},
                 {"city_b", 11, 21},
                 {"city_c", 12, 22}
               ])

      assert length(results) == 2
      assert length(failures) == 1
      assert {"city_b", _reason} = hd(failures)
    end
  end
end
