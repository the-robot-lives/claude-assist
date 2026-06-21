defmodule TheRobotRemembers.Memory.Recall do
  @moduledoc """
  Retrieval. `by_emotion/3` is the headline path — a pgvector L2 ANN over the 7-d emotional
  vector (works with no external services). `active/3` fuses the four Weaviate named-vector
  searches (or a `pg_trgm` lexical fallback) with the emotional path via Reciprocal Rank
  Fusion, then winnows and formats for context injection.
  """
  require Logger
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.Memory
  alias TheRobotRemembers.Schema.Memory.RecallLog
  alias TheRobotRemembers.Memory.{Emotion, Embeddings, VectorStore, Reinforcement}
  alias TheRobotRemembers.Agents.{Monitor, Sentinel}

  @active_states [:active, :consolidating]
  @graph_max_hops 3
  @graph_min_weight 0.2

  def config, do: Application.get_env(:the_robot_remembers, :memory_recall, [])
  defp vector_weights, do: config()[:vector_weights] || %{content: 1.0, context: 0.8, tangent: 0.8, reflection: 0.7}
  defp rrf_k, do: config()[:rrf_k] || 60
  defp cpp, do: config()[:candidates_per_path] || 50
  defp default_limit, do: config()[:default_limit] || 12

  # ── Emotional-resonance recall (pgvector; no external deps) ─────
  def by_emotion(emotional_state, opts \\ [], context \\ %{}) do
    started = System.monotonic_time(:millisecond)
    owner = Sentinel.owner_scope(context)
    limit = opts[:limit] || default_limit()
    {mood, hormones} = split_state(emotional_state, owner)
    qvec = Pgvector.new(Emotion.build_vector(mood, hormones))

    rows =
      base_scope(owner)
      |> order_by([m], asc: l2_distance(m.emotional_embedding, ^qvec), asc: m.id)
      |> limit(^limit)
      |> Repo.all()
      |> Sentinel.authorize(context)
      |> Enum.map(&annotate_resonance(&1, qvec))

    Reinforcement.on_recall(rows, context)
    log(:by_emotion, owner, context, nil, rows, started, %{path: "emotional"})
    {:ok, %{mode: :by_emotion, results: rows, xml: to_xml(rows, mode: "by_emotion")}}
  end

  # ── Active recall (multi-vector + emotional, RRF-fused) ─────────
  def active(query, opts \\ [], context \\ %{}) when is_binary(query) do
    started = System.monotonic_time(:millisecond)
    owner = Sentinel.owner_scope(context)
    limit = opts[:limit] || default_limit()

    semantic_lists = semantic_rank_lists(query, owner)
    emotional_list = emotional_rank_list(owner)

    seed_ids =
      (semantic_lists ++ emotional_list)
      |> Enum.flat_map(fn {_w, _s, ids} -> ids end)
      |> Enum.uniq()
      |> Enum.take(60)

    graph_list = graph_rank_list(owner, seed_ids)
    rank_lists = semantic_lists ++ emotional_list ++ graph_list

    fused = rrf(rank_lists, rrf_k())
    ids = fused |> Enum.map(&elem(&1, 0)) |> Enum.take(limit * 3)

    rows =
      ids
      |> hydrate(owner)
      |> Sentinel.authorize(context)
      |> reorder_by(ids)
      |> Enum.take(limit)

    breakdown = %{
      paths: Enum.map(rank_lists, fn {w, _, ids} -> %{weight: w, kind: :rank, count: length(ids)} end),
      semantic: if(semantic_lists == [], do: "none", else: "weaviate_or_lexical"),
      graph: graph_list != []
    }

    Reinforcement.on_recall(rows, context)
    log(:active, owner, context, query, rows, started, breakdown)
    {:ok, %{mode: :active, results: rows, xml: to_xml(rows, mode: "active", query: query)}}
  end

  # Recursive graph traversal (≤3 hops, weight≥0.2, cycle-guarded, bidirectional), seeded by
  # the semantic+emotional frontier. Returns a single weighted RRF rank-list (by path weight).
  defp graph_rank_list(_owner, []), do: []

  defp graph_rank_list(_owner, seed_ids) do
    sql = """
    WITH RECURSIVE walk(memory_id, depth, path_weight, path) AS (
      SELECT unnest(string_to_array($1, ',')::uuid[]), 0, 1.0::real, ARRAY[]::uuid[]
      UNION ALL
      SELECT CASE WHEN e.source_memory_id = w.memory_id THEN e.target_memory_id ELSE e.source_memory_id END,
             w.depth + 1, w.path_weight * e.weight, w.path || w.memory_id
      FROM walk w
      JOIN association_edges e
        ON (e.source_memory_id = w.memory_id OR e.target_memory_id = w.memory_id) AND e.weight >= $2
      WHERE w.depth < $3
        AND NOT ((CASE WHEN e.source_memory_id = w.memory_id THEN e.target_memory_id ELSE e.source_memory_id END) = ANY(w.path))
    )
    SELECT memory_id::text, MAX(path_weight) AS pw
    FROM walk WHERE depth > 0
    GROUP BY memory_id ORDER BY pw DESC, memory_id LIMIT $4
    """

    case Ecto.Adapters.SQL.query(Repo, sql, [Enum.join(seed_ids, ","), @graph_min_weight, @graph_max_hops, cpp()]) do
      {:ok, %{rows: rows}} ->
        case Enum.map(rows, fn [id, _pw] -> id end) do
          [] -> []
          ids -> [{0.8, {:graph, :cte}, ids}]
        end

      _ ->
        []
    end
  end

  # ── semantic paths ─────────────────────────────────────────────
  defp semantic_rank_lists(query, owner) do
    cond do
      Embeddings.configured?() and VectorStore.configured?() ->
        case Embeddings.embed_one(query) do
          {:ok, qvec} -> weaviate_lists(qvec, owner)
          _ -> [lexical_list(query, owner)]
        end

      true ->
        [lexical_list(query, owner)]
    end
  end

  defp weaviate_lists(qvec, owner) do
    filters = if owner, do: %{"owner_agent" => owner}, else: %{}

    for nv <- VectorStore.named_vectors() do
      weight = Map.get(vector_weights(), String.to_atom(nv), 0.7)

      ids =
        case VectorStore.search(nv, qvec, limit: cpp(), filters: filters) do
          {:ok, hits} -> Enum.map(hits, & &1.memory_id)
          _ -> []
        end

      {weight, {:weaviate, nv}, ids}
    end
  end

  defp lexical_list(query, owner) do
    # Only genuine trigram matches enter the lexical list (so non-matching memories don't earn
    # RRF credit just by being in the top-N), and an explicit text query outweighs ambient
    # emotional resonance (weight 2.0) — the caller typed these words, honor them.
    ids =
      base_scope(owner)
      |> where([m], fragment("similarity(?, ?) > 0.03", m.content, ^query))
      |> order_by([m], desc: fragment("similarity(?, ?)", m.content, ^query), asc: m.id)
      |> limit(^cpp())
      |> select([m], m.id)
      |> Repo.all()

    {2.0, {:lexical, :content}, ids}
  end

  defp emotional_rank_list(owner) do
    %{mood: mood, hormones: hormones} = Monitor.current_emotional(owner)
    qvec = Pgvector.new(Emotion.build_vector(mood, hormones))

    ids =
      base_scope(owner)
      |> order_by([m], asc: l2_distance(m.emotional_embedding, ^qvec), asc: m.id)
      |> limit(^cpp())
      |> select([m], m.id)
      |> Repo.all()

    # Ambient current mood is a secondary signal for an explicit text query (the lexical/semantic
    # match leads); for `recall_by_emotion` the emotional vector is queried directly, not here.
    [{0.45, {:emotional, :vad}, ids}]
  end

  # ── Reciprocal Rank Fusion ─────────────────────────────────────
  defp rrf(rank_lists, k) do
    rank_lists
    |> Enum.reduce(%{}, fn {weight, _src, ids}, acc ->
      ids
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {id, idx}, a ->
        Map.update(a, id, weight / (k + idx + 1), &(&1 + weight / (k + idx + 1)))
      end)
    end)
    |> Enum.sort_by(fn {_id, s} -> -s end)
  end

  # ── query/hydration helpers ────────────────────────────────────
  defp base_scope(owner) do
    q = from(m in Memory, where: m.state in @active_states)
    if owner, do: where(q, [m], m.owner_agent == ^owner), else: where(q, [m], m.classification == :open)
  end

  defp hydrate([], _owner), do: []
  defp hydrate(ids, owner) do
    base_scope(owner) |> where([m], m.id in ^ids) |> Repo.all()
  end

  defp reorder_by(rows, ids) do
    by_id = Map.new(rows, &{&1.id, &1})
    ids |> Enum.map(&Map.get(by_id, &1)) |> Enum.reject(&is_nil/1)
  end

  defp split_state(%{mood: mood} = s, _owner), do: {mood, Map.get(s, :hormones, %{})}
  defp split_state(%{"mood" => mood} = s, _owner), do: {mood, Map.get(s, "hormones", %{})}
  defp split_state(flat, owner) when is_map(flat) do
    # treat a flat map as mood; hormones come from the harness (Monitor)
    {flat, Monitor.current_hormones(owner)}
  end
  defp split_state(_, owner), do: {Emotion.neutral_mood(), Monitor.current_hormones(owner)}

  defp annotate_resonance(mem, qvec) do
    res =
      case mem.emotional_embedding do
        %Pgvector{} = v -> Emotion.resonance(Pgvector.to_list(qvec), Pgvector.to_list(v))
        _ -> nil
      end

    Map.put(mem, :resonance, res)
  end

  # ── context-injection formatting ───────────────────────────────
  def to_xml(rows, meta) do
    mode = meta[:mode] || "active"
    inner = Enum.map_join(rows, "\n", &memory_xml/1)

    "<memories recalled=\"#{length(rows)}\" mode=\"#{mode}\">\n" <> inner <> "\n</memories>"
  end

  defp memory_xml(mem) do
    res = if r = Map.get(mem, :resonance), do: " resonance=\"#{Float.round(r, 2)}\"", else: ""
    formed = if mem.occurred_at, do: DateTime.to_iso8601(mem.occurred_at), else: ""
    body = mem.summary || mem.content || ""

    "  <memory id=\"#{mem.id}\"#{res} mood=\"v#{fmt(mem.valence)} a#{fmt(mem.arousal)}\" " <>
      "formed=\"#{formed}\" domain=\"#{mem.domain || ""}\">\n" <>
      "    #{escape(body)}\n" <>
      tangent_line(mem) <>
      "  </memory>"
  end

  defp tangent_line(%{tangent: t}) when is_binary(t) and t != "",
    do: "    <tangent>#{escape(t)}</tangent>\n"

  defp tangent_line(_), do: ""

  defp fmt(n) when is_number(n), do: Float.round(n * 1.0, 2)
  defp fmt(_), do: 0.0

  defp escape(s) when is_binary(s) do
    s |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
  end
  defp escape(_), do: ""

  # ── recall_log (best-effort) ───────────────────────────────────
  defp log(mode, owner, context, query, rows, started, breakdown) do
    duration = System.monotonic_time(:millisecond) - started

    %RecallLog{}
    |> RecallLog.changeset(%{
      requester_id: context[:requester_id] || owner || "anonymous",
      owner_agent: owner || "anonymous",
      mode: to_string(mode),
      query: query,
      total_candidates: length(rows),
      returned_count: length(rows),
      duration_ms: duration,
      result_memory_ids: Enum.map(rows, & &1.id),
      path_breakdown: breakdown,
      occurred_at: DateTime.utc_now()
    })
    |> Repo.insert()
  rescue
    e -> Logger.warning("[Recall] log failed: #{inspect(e)}")
  end
end
