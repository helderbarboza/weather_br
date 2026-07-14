# WeatherBr

[![CI](https://github.com/helderbarboza/weather_br/actions/workflows/ci.yml/badge.svg)](https://github.com/helderbarboza/weather_br/actions/workflows/ci.yml)
[![Elixir](https://img.shields.io/badge/elixir-1.20-4B275F?style=flat&logo=elixir&logoColor=white)](mix.exs)

**WeatherBr** is an Elixir library that fetches weather forecast data from the [Open-Meteo API](https://open-meteo.com/) for major Brazilian cities and computes average daily maximum temperatures with precise decimal arithmetic.

## Technology Stack

| Technology                                   | Version | Purpose                         |
| -------------------------------------------- | ------- | ------------------------------- |
| Elixir                                       | ~> 1.20 | Language & runtime              |
| [Req](https://hex.pm/packages/req)           | ~> 0.6  | HTTP client                     |
| [Decimal](https://hex.pm/packages/decimal)   | ~> 3.1  | Arbitrary-precision arithmetic  |
| [Plug](https://hex.pm/packages/plug)         | ~> 1.20 | HTTP stubbing in tests          |
| [Credo](https://hex.pm/packages/credo)       | ~> 1.7  | Static code analysis (dev/test) |
| [Dialyxir](https://hex.pm/packages/dialyxir) | ~> 1.2  | Dialyzer integration (dev)      |

## Architecture

The project follows a **two-layer facade pattern**:

- `WeatherBr` — entrypoint module with `run/0` (default 6 days) that fetches, averages, and prints formatted results.
- `WeatherBr.Weather` — public API facade containing hardcoded city coordinates and the `average/1` helper.
- `WeatherBr.Weather.OpenMeteo` — HTTP client wrapper around the Open-Meteo `/v1/forecast` endpoint. Fetches forecasts concurrently (up to 5 parallel tasks, 10s timeout per task).

## Getting Started

### Prerequisites

- Elixir ~> 1.20
- Erlang/OTP 26+

### Installation

```bash
git clone <repo-url>
cd weather_br
mix deps.get
```

### Usage

```elixir
iex -S mix

iex> WeatherBr.run()
"São Paulo: 21.3°C\nBelo Horizonte: 22.0°C\nCuritiba: 18.8°C"
```

Or fetch raw data:

```elixir
iex> WeatherBr.Weather.get_average_temperatures()
[
  {"São Paulo", Decimal.new("21.3")},
  {"Belo Horizonte", Decimal.new("22.0")},
  {"Curitiba", Decimal.new("18.8")}
]
```

No API key is required — Open-Meteo is a free, open-source weather API.

## Key Features

- **Concurrent HTTP requests** — uses `Task.async_stream` with max 5 parallel tasks and 10s timeout
- **Precise averaging** — temperature averages computed with `Decimal` to avoid floating-point drift
- **Formatted output** — `WeatherBr.run/1` prints `city: temperature°C` directly to the console
- **Graceful error handling** — per-city error messages when an individual forecast request fails
- **6-day forecast window** — configurable from 1 to 7 days

## Development Workflow

### Setup

```bash
mix deps.get          # Fetch dependencies
mix compile           # Compile with warnings as errors
```

### Linting & Static Analysis

```bash
mix lint              # Full lint: compile + format + Credo strict + Dialyzer
mix lint:quick        # Quick lint: compile + format + Credo (warnings only)
mix format            # Auto-format all sources
```

The `mix lint` alias runs:
1. `compile --warnings-as-errors`
2. `format --check-formatted`
3. `credo --strict`
4. `dialyzer`
