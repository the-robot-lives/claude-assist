defmodule GenAI.InferenceProvider.Helpers do
  @moduledoc """
  Inference Provider Helpers.
  """

  # Finch Call Options
  defp finch_options(options) do
    pool_timeout = options[:pool_timeout] || 600_000
    receive_timeout = options[:receive_timeout] || 600_000
    request_timeout = options[:request_timeout] || 600_000

    [
      pool_timeout: pool_timeout,
      receive_timeout: receive_timeout,
      request_timeout: request_timeout
    ]
  end

  @doc """
  Make API Call Via Finch.
  """
  def api_call(type, url, headers, body \\ nil, options \\ [])

  def api_call(type, url, headers, body = nil, options) do
    Finch.build(type, url, headers, body)
    |> Finch.request(GenAI.Finch, finch_options(options))
  end

  def api_call(type, url, headers, body, options) do
    with {:ok, serialized_body} <- Jason.encode(body) do
      Finch.build(type, url, headers, serialized_body)
      |> Finch.request(GenAI.Finch, finch_options(options))
    else
      error ->
        raise GenAI.RequestError,
          message: "Failed to encode request body: #{inspect(body)}",
          details: error
    end
  end
  
  
  
  @doc """
  Make API Call Via Finch.
  """
  def stream_api_call(handler, type, url, headers, body \\ nil, options \\ [])
  
  def stream_api_call({acc, cb}, type, url, headers, body = nil, options) do
    Finch.build(type, url, headers, body)
    |> Finch.stream_while(GenAI.Finch, acc, cb, finch_options(options))
  end
  
  def stream_api_call({acc, cb}, type, url, headers, body, options) do
    with {:ok, serialized_body} <- Jason.encode(body) do
      Finch.build(type, url, headers, serialized_body)
      |> Finch.stream_while(GenAI.Finch, acc, cb, finch_options(options))
    else
      error ->
        raise GenAI.RequestError,
              message: "Failed to encode request body: #{inspect(body)}",
              details: error
    end
  end
  
  @doc """
  Set required setting or raise RequestError if not present.
  """
  def with_required_setting(body, setting, settings) do
    case settings[setting] do
      nil ->
        raise GenAI.RequestError, "Missing required setting: #{setting}"

      v ->
        Map.put(body, setting, v)
    end
  end

  @doc """
  Set optional field if present.
  """
  def optional_field(body, _, nil), do: body

  def optional_field(body, field, value) do
    Map.put(body, field, value)
  end

  @doc """
  Apply setting or default value if not present.
  """
  def with_setting(body, setting, settings, default \\ nil)

  def with_setting(body, setting, settings, default) do
    with_setting_as(body, setting, setting, settings, default)
  end

  @doc """
  Apply setting as_setting or default value if not present.
  """
  def with_setting_as(body, as_setting, setting, settings, default \\ nil)
  
  def with_setting_as(body, as_setting, setting, settings, default) do
    value = Keyword.get(settings, setting, default)
    if value || value === false do
      Map.put(body, as_setting, value)
    else
      body
    end
  end
end
