import Config

config :weather_br,
  http_client_options: [
    plug: {Req.Test, WeatherBr.Weather.OpenMeteo.Client},
    cachex: false,
    retry: false
  ]
