# WeatherBr

[![CI](https://github.com/helderbarboza/weather_br/actions/workflows/ci.yml/badge.svg)](https://github.com/helderbarboza/weather_br/actions/workflows/ci.yml)
[![Elixir](https://img.shields.io/badge/elixir-1.20-4B275F?style=flat&logo=elixir&logoColor=white)](mix.exs)

**WeatherBr** is an Elixir library that fetches weather forecast data from the [Open-Meteo API](https://open-meteo.com/) for major Brazilian cities and computes average daily maximum temperatures with precise decimal arithmetic.

## Technology Stack

| Technology                                   | Purpose                         |
| -------------------------------------------- | ------------------------------- |
| Elixir                                       | Language & runtime              |
| [Req](https://hex.pm/packages/req)           | HTTP client                     |
| [Decimal](https://hex.pm/packages/decimal)   | Arbitrary-precision arithmetic  |
| [Plug](https://hex.pm/packages/plug)         | HTTP stubbing in tests          |
| [Cachex](https://hex.pm/packages/cachex)     | In-memory request caching       |
| [Credo](https://hex.pm/packages/credo)       | Static code analysis (dev/test) |
| [Dialyxir](https://hex.pm/packages/dialyxir) | Dialyzer integration (dev)      |

## Architecture

The project follows a **three-layer facade pattern** with caching:

- `WeatherBr.Application` — OTP Application with a `one_for_one` supervisor; starts the `:weather_cache` Cachex instance and manages the process lifecycle.
- `WeatherBr` — entrypoint module with `run/0` (default 6 days) that fetches, averages, and prints formatted results.
- `WeatherBr.Weather` — public API facade containing hardcoded city coordinates and the `average/1` helper.
- `WeatherBr.Weather.OpenMeteo` — orchestrates concurrent fetches (up to 5 parallel tasks, 15s timeout per task) via `Task.async_stream`, delegates HTTP to `OpenMeteo.Client`, and maps errors to the typed `OpenMeteo.Error` struct.
- `WeatherBr.Req.CachexStep` — Req step plugin that intercepts requests and responses. On a cache hit, it returns the cached response (skipping the HTTP call); on a cache miss, it stores the response in Cachex with a configurable TTL (default 5 minutes).

## Getting Started

### Prerequisites

- Elixir ~> 1.20
- Erlang/OTP 26+
- [asdf](https://asdf-vm.com) (Optional) — run `asdf install` to install the exact versions pinned in `.tool-versions`

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
iex> WeatherBr.Weather.get_average_temperatures(6)
[
  {"São Paulo", Decimal.new("21.3")},
  {"Belo Horizonte", Decimal.new("22.0")},
  {"Curitiba", Decimal.new("18.8")}
]
```

No API key is required — Open-Meteo is a free, open-source weather API.

## Key Features

- **In-memory request caching** — HTTP responses cached in Cachex with a 5-minute TTL via a custom Req step plugin; repeated calls return instantly from memory, no network round-trip.
- **Concurrent HTTP requests** — uses `Task.async_stream` with max 5 parallel tasks and 15s timeout
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
