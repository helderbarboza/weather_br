defmodule WeatherBr.MixProject do
  use Mix.Project

  def project do
    [
      app: :weather_br,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: aliases()
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
      {:plug, "~> 1.20"},
      # Linting
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp aliases do
    [
      lint: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "cmd mkdir -p priv/plts",
        "dialyzer"
      ],
      "lint:quick": [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --only warning"
      ]
    ]
  end
end
