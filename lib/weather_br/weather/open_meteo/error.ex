defmodule WeatherBr.Weather.OpenMeteo.Error do
  defexception [:message, :reason, :status, :city, :type]

  @type type :: :api | :http | :parse | :validation

  @type t :: %__MODULE__{
          message: String.t(),
          reason: String.t() | nil,
          status: non_neg_integer() | nil,
          city: String.t() | nil,
          type: type()
        }

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    type = Keyword.fetch!(opts, :type)
    reason = Keyword.get(opts, :reason)
    status = Keyword.get(opts, :status)
    city = Keyword.get(opts, :city)

    message =
      case type do
        :api -> "API error#{for_city(city)}: #{reason}"
        :http -> "HTTP #{status || "??"} error#{for_city(city)}: #{reason}"
        :parse -> "response parse error#{for_city(city)}: #{reason}"
        :validation -> "validation error: #{reason}"
      end

    %__MODULE__{message: message, reason: reason, status: status, city: city, type: type}
  end

  @impl true
  def exception(opts) do
    new(opts)
  end

  defp for_city(nil), do: ""
  defp for_city(city), do: " for #{city}"
end
