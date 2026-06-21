defmodule TheRobotRemembers.Memory.Embeddings do
  @moduledoc """
  Text → vector embeddings behind a swappable behaviour. Default adapter: OpenAI
  (`text-embedding-3-small`, 1536-d) called directly over `req` — `genai 0.3` has no
  embeddings API. Vectors are returned as plain lists of floats, in input order.

  Not configured (no `OPENAI_API_KEY`) → `{:error, :not_configured}`, so the rest of the
  engine still runs (emotional-resonance recall needs no text embeddings).
  """
  require Logger

  @callback embed([String.t()]) :: {:ok, [[float()]]} | {:error, term()}

  def config, do: Application.get_env(:the_robot_remembers, :embeddings, [])
  def dimensions, do: config()[:dimensions] || 1536
  def model, do: config()[:model] || "text-embedding-3-small"
  def configured?, do: is_binary(config()[:api_key]) and config()[:api_key] != ""

  @doc "Embed a list of (non-blank) texts. Vectors returned in the same order."
  @spec embed([String.t()]) :: {:ok, [[float()]]} | {:error, term()}
  def embed([]), do: {:ok, []}

  def embed(texts) when is_list(texts) do
    if configured?(), do: do_embed(texts), else: {:error, :not_configured}
  end

  @spec embed_one(String.t()) :: {:ok, [float()]} | {:error, term()}
  def embed_one(text) when is_binary(text) do
    with {:ok, [vec]} <- embed([text]), do: {:ok, vec}
  end

  defp do_embed(texts) do
    cfg = config()
    url = (cfg[:api_base] || "https://api.openai.com/v1") <> "/embeddings"

    request =
      Req.post(url,
        json: %{model: model(), input: texts},
        auth: {:bearer, cfg[:api_key]},
        receive_timeout: cfg[:timeout_ms] || 8_000
      )

    case request do
      {:ok, %Req.Response{status: 200, body: %{"data" => data}}} ->
        {:ok, data |> Enum.sort_by(& &1["index"]) |> Enum.map(& &1["embedding"])}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("[Embeddings] provider returned #{status}: #{inspect(body)}")
        {:error, {:http, status}}

      {:error, reason} ->
        Logger.warning("[Embeddings] request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
