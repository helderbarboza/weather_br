defmodule WeatherBrTest do
  use ExUnit.Case
  doctest WeatherBr

  test "greets the world" do
    assert WeatherBr.hello() == :world
  end
end
