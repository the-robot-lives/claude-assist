defmodule TheRobotRemembers.Agents.Weaver do
  @moduledoc """
  The Weaver builds the association graph. For a newly-formed memory it creates weighted edges
  across several dimensions:

    * **emotional** — pgvector L2 neighbors over the 7-d emotional vector (resonance ≥ threshold)
    * **temporal**  — memories within a time window (proximity-weighted)
    * **contextual**— shared domain
    * **tangent**   — the agent's own associative leap: embed the `tangent` and link to the
      memory whose content/reflection it most resonates with (Weaviate path)
    * **semantic**  — content-vector neighbors (Weaviate path)

  PG-based dimensions always run; the Weaviate-based ones (tangent/semantic) run only when the
  VectorStore is enabled. Edges are directional rows inserted `on_conflict: :nothing`
  (idempotent); reinforcement strengthens them later.
  """
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge}
  alias TheRobotRemembers.Memory.{Emotion, Embeddings, VectorStore}

  @active [:active, :consolidating]

  def config, do: Application.get_env(:the_robot_remembers, :weaver, [])
  defp emo_min, do: config()[:emotional_resonance_min] || 0.85
  defp emo_k, do: config()[:emotional_k] || 8
  defp temporal_window_s, do: config()[:temporal_window_s] || 3600
  defp max_per_dim, do: config()[:max_edges_per_dim] || 8
  defp w, do: config()[:weights] || %{emotional: 0.5, temporal: 0.4, contextual: 0.4, tangent: 0.6, semantic: 0.6}

  @doc "Create association edges for a memory id. Returns the count created/attempted."
  def link(memory_id) when is_binary(memory_id) do
    case Repo.get(Memory, memory_id) do
      nil -> {:ok, 0}
      mem -> {:ok, link_memory(mem)}
    end
  end

  defp link_memory(mem) do
    [
      emotional_edges(mem),
      temporal_edges(mem),
      contextual_edges(mem),
      tangent_edges(mem),
      semantic_edges(mem)
    ]
    |> List.flatten()
    |> Enum.sum()
  end

  # ── emotional (pgvector) ────────────────────────────────────────
  defp emotional_edges(%{emotional_embedding: nil}), do: 0

  defp emotional_edges(mem) do
    src = Pgvector.to_list(mem.emotional_embedding)
    qvec = mem.emotional_embedding

    candidates =
      base(mem)
      |> order_by([m], l2_distance(m.emotional_embedding, ^qvec))
      |> limit(^emo_k())
      |> select([m], %{id: m.id, vec: m.emotional_embedding})
      |> Repo.all()

    for c <- candidates,
        res = Emotion.resonance(src, Pgvector.to_list(c.vec)),
        res >= emo_min(),
        reduce: 0 do
      acc ->
        acc + create_edge(mem.id, c.id, :emotional, res, "emotional resonance #{Float.round(res, 2)}", %{emotional_similarity: res})
    end
  end

  # ── temporal ────────────────────────────────────────────────────
  defp temporal_edges(%{occurred_at: nil}), do: 0

  defp temporal_edges(mem) do
    window = temporal_window_s()

    candidates =
      base(mem)
      |> where([m], fragment("abs(extract(epoch from (? - ?)))", m.occurred_at, ^mem.occurred_at) <= ^window)
      |> limit(^max_per_dim())
      |> select([m], %{id: m.id, occurred_at: m.occurred_at})
      |> Repo.all()

    for c <- candidates, reduce: 0 do
      acc ->
        prox = temporal_proximity(mem.occurred_at, c.occurred_at, window)
        acc + create_edge(mem.id, c.id, :temporal, w()[:temporal] * prox, "temporal proximity", %{temporal_proximity: prox})
    end
  end

  defp temporal_proximity(a, b, window) do
    delta = abs(DateTime.diff(a, b, :second))
    max(0.0, 1.0 - delta / window)
  end

  # ── contextual (shared domain) ──────────────────────────────────
  defp contextual_edges(%{domain: nil}), do: 0
  defp contextual_edges(%{domain: ""}), do: 0

  defp contextual_edges(mem) do
    candidates =
      base(mem)
      |> where([m], m.domain == ^mem.domain)
      |> limit(^max_per_dim())
      |> select([m], m.id)
      |> Repo.all()

    Enum.reduce(candidates, 0, fn id, acc ->
      acc + create_edge(mem.id, id, :contextual, w()[:contextual], "shared domain #{mem.domain}", %{})
    end)
  end

  # ── tangent-seeded (Weaviate) — the agent authoring a link ──────
  defp tangent_edges(%{tangent: t}) when not is_binary(t), do: 0
  defp tangent_edges(%{tangent: ""}), do: 0

  defp tangent_edges(mem) do
    with true <- VectorStore.enabled?() and Embeddings.configured?(),
         {:ok, tvec} <- Embeddings.embed_one(mem.tangent) do
      ["content", "reflection"]
      |> Enum.flat_map(fn nv ->
        case VectorStore.search(nv, tvec, limit: 3, filters: %{"owner_agent" => mem.owner_agent}) do
          {:ok, hits} -> hits
          _ -> []
        end
      end)
      |> Enum.map(& &1.memory_id)
      |> Enum.reject(&(&1 == mem.id))
      |> Enum.uniq()
      |> Enum.take(2)
      |> Enum.reduce(0, fn id, acc ->
        acc + create_edge(mem.id, id, :tangent, w()[:tangent], "tangent: #{String.slice(mem.tangent, 0, 80)}", %{})
      end)
    else
      _ -> 0
    end
  end

  # ── semantic (Weaviate content vector) ──────────────────────────
  defp semantic_edges(%{content: c}) when not is_binary(c), do: 0

  defp semantic_edges(mem) do
    with true <- VectorStore.enabled?() and Embeddings.configured?(),
         {:ok, cvec} <- Embeddings.embed_one(mem.content),
         {:ok, hits} <- VectorStore.search("content", cvec, limit: emo_k(), filters: %{"owner_agent" => mem.owner_agent}) do
      hits
      |> Enum.map(& &1.memory_id)
      |> Enum.reject(&(&1 == mem.id))
      |> Enum.uniq()
      |> Enum.take(max_per_dim())
      |> Enum.reduce(0, fn id, acc ->
        acc + create_edge(mem.id, id, :semantic, w()[:semantic], "semantic similarity", %{})
      end)
    else
      _ -> 0
    end
  end

  # ── edge insert (idempotent) ────────────────────────────────────
  defp create_edge(src, tgt, _type, _weight, _reason, _extra) when src == tgt, do: 0

  defp create_edge(src, tgt, type, weight, reason, extra) do
    attrs =
      Map.merge(
        %{
          source_memory_id: src,
          target_memory_id: tgt,
          edge_type: type,
          weight: clamp(weight),
          created_by: "weaver",
          reason: reason,
          last_reinforced_at: DateTime.utc_now()
        },
        extra
      )

    case %AssociationEdge{}
         |> AssociationEdge.changeset(attrs)
         |> Repo.insert(on_conflict: :nothing, conflict_target: [:source_memory_id, :target_memory_id, :edge_type]) do
      {:ok, _} -> 1
      _ -> 0
    end
  end

  defp base(mem) do
    from(m in Memory,
      where: m.state in @active and m.owner_agent == ^mem.owner_agent and m.id != ^mem.id
    )
  end

  defp clamp(w), do: w |> max(0.05) |> min(1.0)
end
