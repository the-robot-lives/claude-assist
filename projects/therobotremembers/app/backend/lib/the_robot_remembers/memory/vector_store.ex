defmodule TheRobotRemembers.Memory.VectorStore do
  @moduledoc """
  Weaviate-backed store for the four named text vectors per memory
  (`content`/`context`/`reflection`/`tangent`), BYO-vector (`vectorizer: none`).

  Uses **`noizu_weaviate`** (our Weaviate client) for transport/auth/endpoint via its public
  `Noizu.Weaviate.api_call/5` primitive. The named-vector bodies are sent as raw maps because
  `noizu_weaviate`'s high-level `DataObject` struct currently models only a single vector.

  Config:
    * endpoint — `config :noizu_weaviate, endpoint: "…/"` (compile-time in `noizu_weaviate`)
    * api key  — `config :noizu_weaviate, weaviate_api_key: …` (runtime)
    * gate     — `config :the_robot_remembers, :weaviate, enabled: true, class: "TrrMemory"`

  Disabled by default → all ops no-op so emotional-resonance + lexical recall work without
  Weaviate. Needs live verification against the cluster instance.
  """
  require Logger

  @named_vectors ~w(content context reflection tangent)
  def named_vectors, do: @named_vectors

  def config, do: Application.get_env(:the_robot_remembers, :weaviate, [])
  def class, do: config()[:class] || "TrrMemory"
  def enabled?, do: config()[:enabled] == true
  def configured?, do: enabled?()

  defp base, do: Noizu.Weaviate.api_base()
  defp call(method, path, body), do: Noizu.Weaviate.api_call(method, base() <> path, body, :json, %{})

  @doc "Create the class with four named BYO vectors if absent. Idempotent."
  def ensure_class do
    if enabled?() do
      case call(:get, "v1/schema/#{class()}", nil) do
        {:ok, %{"class" => _}} -> :ok
        _ -> create_class()
      end
    else
      {:error, :disabled}
    end
  end

  defp create_class do
    vector_config = Map.new(@named_vectors, fn n -> {n, %{vectorizer: %{none: %{}}, vectorIndexType: "hnsw"}} end)

    body = %{
      class: class(),
      vectorConfig: vector_config,
      properties: [
        %{name: "memory_id", dataType: ["text"]},
        %{name: "owner_agent", dataType: ["text"]},
        %{name: "compartment", dataType: ["text"]},
        %{name: "classification", dataType: ["text"]},
        %{name: "content_type", dataType: ["text"]}
      ]
    }

    case call(:post, "v1/schema", body) do
      {:ok, _} -> :ok
      other -> log_err("create_class", other)
    end
  end

  @doc "Upsert a memory's named vectors + filter props. `vectors`: `%{\"content\" => [..], ...}`."
  def upsert(memory_id, vectors, props) when is_map(vectors) and is_map(props) do
    if enabled?() do
      body = %{
        class: class(),
        id: memory_id,
        properties: Map.put(props, "memory_id", memory_id),
        vectors: vectors
      }

      case call(:post, "v1/objects", body) do
        {:ok, _} -> :ok
        other -> log_err("upsert", other)
      end
    else
      {:error, :disabled}
    end
  end

  @doc "Search one named vector. Returns `{:ok, [%{memory_id, score}]}` (score = 1 - distance)."
  def search(named_vector, query_vec, opts \\ []) when named_vector in @named_vectors do
    if enabled?() do
      limit = opts[:limit] || 50
      where = build_where(opts[:filters] || %{})

      gql =
        "{ Get { #{class()}(limit: #{limit}, " <>
          "nearVector: {vector: #{Jason.encode!(query_vec)}, targetVectors: [\"#{named_vector}\"]}" <>
          where <> ") { memory_id _additional { distance } } } }"

      case call(:post, "v1/graphql", %{query: gql}) do
        {:ok, %{"data" => %{"Get" => get}}} when is_map(get) ->
          rows = Map.get(get, class(), []) || []

          {:ok,
           Enum.map(rows, fn r ->
             dist = get_in(r, ["_additional", "distance"]) || 1.0
             %{memory_id: r["memory_id"], score: 1.0 - dist}
           end)}

        other ->
          log_err("search", other)
      end
    else
      {:error, :disabled}
    end
  end

  def delete(memory_id) do
    if enabled?(), do: call(:delete, "v1/objects/#{class()}/#{memory_id}", nil), else: :ok
    :ok
  end

  defp build_where(filters) when map_size(filters) == 0, do: ""

  defp build_where(filters) do
    operands =
      Enum.map(filters, fn {k, v} ->
        "{path: [\"#{k}\"], operator: Equal, valueText: #{Jason.encode!(to_string(v))}}"
      end)

    ", where: {operator: And, operands: [#{Enum.join(operands, ", ")}]}"
  end

  defp log_err(op, other) do
    Logger.warning("[VectorStore] #{op} failed: #{inspect(other)}")
    {:error, other}
  end
end
