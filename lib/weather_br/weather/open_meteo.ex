defmodule WeatherBr.Weather.OpenMeteo do
  def new(opts \\ []) do
    [
      url: "https://api.open-meteo.com/v1/forecast",
      redirect: true,
      compressed: true
    ]
    |> Keyword.merge(Application.get_env(:weather_br, :http_client_options, []))
    |> Keyword.merge(opts)
    |> Req.new()
  end

  def get_temperatures(cities) do
    cities
    |> Task.async_stream(
      fn {city_name, lat, lon} ->
        req =
          new(
            params: [
              latitude: lat,
              longitude: lon,
              daily: "temperature_2m_max",
              timezone: "America/Sao_Paulo"
            ]
          )

        response = Req.get!(req)
        %{"daily" => %{"temperature_2m_max" => temperatures}} = response.body
        temperatures = Enum.take(temperatures, 6)
        average_temperature = average(temperatures)

        {city_name, average_temperature}
      end,
      max_concurrency: 5,
      timeout: 10_000
    )
    |> Enum.map(fn {:ok, result} -> result end)
  end

  defp average(numbers) do
    length = Enum.count(numbers)

    numbers
    |> Enum.map(&Decimal.from_float/1)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
    |> Decimal.div(length)
  end
end
