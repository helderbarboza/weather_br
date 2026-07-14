defmodule WeatherBrTest do
  use ExUnit.Case, async: true

  describe "format/1" do
    test "formats results with city, temperature, and °C" do
      result =
        {:ok,
         [
           {"São Paulo", Decimal.new("30.5")},
           {"Belo Horizonte", Decimal.new("27.8")},
           {"Curitiba", Decimal.new("22.1")}
         ], []}

      assert WeatherBr.format(result) ==
               "São Paulo: 30.5°C\nBelo Horizonte: 27.8°C\nCuritiba: 22.1°C"
    end

    test "rounds to one decimal place" do
      result = {:ok, [{"Test", Decimal.new("28.55")}, {"Test2", Decimal.new("28.5499")}], []}

      assert WeatherBr.format(result) == "Test: 28.6°C\nTest2: 28.5°C"
    end

    test "handles single result" do
      result = {:ok, [{"Only", Decimal.new("25.0")}], []}

      assert WeatherBr.format(result) == "Only: 25.0°C"
    end

    test "formats failures when some cities failed" do
      result =
        {:ok,
         [
           {"São Paulo", Decimal.new("30.5")}
         ],
         [
           {"Belo Horizonte", "API error for Belo Horizonte: bad coords"}
         ]}

      assert WeatherBr.format(result) ==
               "São Paulo: 30.5°C\n\nFailed cities:\n  Belo Horizonte: API error for Belo Horizonte: bad coords"
    end
  end
end
