defmodule WeatherBr.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cachex, [:weather_cache]}
    ]

    opts = [strategy: :one_for_one, name: WeatherBr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
