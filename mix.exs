defmodule WeatherBr.MixProject do
  use Mix.Project

  def project do
    [
      app: :weather_br,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.6"},
      {:decimal, "~> 3.1"},
      {:plug, "~> 1.20"}
    ]
  end
end
