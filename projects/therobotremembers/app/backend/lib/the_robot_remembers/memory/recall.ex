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
  alias TheRobotRemembers.Memory.{Emotion, Embeddings, VectorStore, Reinforcement, GraphStore}
  alias TheRobotRemembers.Agents.{Monitor, Sentinel}

  @active_states [:active, :consolidating]
  @graph_max_hops 3
  @graph_min_weight 0.2
  # Per-node fan-out cap: the walk follows only the N strongest edges per node. Without this a
  # dense association graph (e.g. an agent with thousands of edges) makes the recursive walk
  # combinatorial — hundreds of thousands of paths that spill to disk and stall. Capping fan-out
  # bounds the walk to ~N^hops paths and focuses traversal on the strongest associations.
  @graph_fanout 8

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

  # ── Recall preview (side-effect-free; per-result RRF contribution breakdown) ──
  # Additive path for the memory console (API contract Phase D). Same rank assembly as active/3
  # but: (1) NO Reinforcement.on_recall (no Hebbian writes), (2) recall_log written with mode
  # "preview", (3) each result carries its per-source RRF contributions. `query` and `mood` are
  # each optional (the caller must supply at least one); `overrides` remaps Recall.config knobs
  # (rrf_k, vector_weights) for this call only. The CTE traversal (graph_rank_list) is unchanged.
  def preview(query, opts \\ [], context \\ %{}) do
    started = System.monotonic_time(:millisecond)
    owner = Sentinel.owner_scope(context)
    limit = opts[:limit] || default_limit()
    overrides = normalize_overrides(opts[:overrides])
    mood = opts[:mood]
    k = overrides[:rrf_k] || rrf_k()

    semantic_lists =
      if is_binary(query) and String.trim(query) != "" do
        semantic_rank_lists(query, owner) |> apply_vector_weights(overrides)
      else
        []
      end

    emotional_list = emotional_rank_list_for(owner, mood)

    seed_ids =
      (semantic_lists ++ emotional_list)
      |> Enum.flat_map(fn {_w, _s, ids} -> ids end)
      |> Enum.uniq()
      |> Enum.take(60)

    graph_list = graph_rank_list(owner, seed_ids)
    rank_lists = semantic_lists ++ emotional_list ++ graph_list

    {fused, contribs} = rrf_detailed(rank_lists, k)
    score_by_id = Map.new(fused)
    ids = fused |> Enum.map(&elem(&1, 0)) |> Enum.take(limit * 3)

    rows =
      ids
      |> hydrate(owner)
      |> Sentinel.authorize(context)
      |> reorder_by(ids)
      |> Enum.take(limit)

    results =
      Enum.map(rows, fn mem ->
        %{memory: mem, score: Map.get(score_by_id, mem.id, 0.0), contributions: Map.get(contribs, mem.id, [])}
      end)

    log(:preview, owner, context, query, rows, started, %{path: "preview"})
    {:ok, %{mode: :preview, results: results, duration_ms: System.monotonic_time(:millisecond) - started}}
  end

  # Recursive graph traversal (≤3 hops, weight≥0.2, cycle-guarded, bidirectional), seeded by
  # the semantic+emotional frontier. Returns a single weighted RRF rank-list (by path weight).
  defp graph_rank_list(_owner, []), do: []

  defp graph_rank_list(_owner, seed_ids) do
    # ADR-006 seam: the traversal runs through the configured GraphStore adapter (:cte default —
    # the same SQL as before; :age when the graph layer is on). One weighted RRF rank-list, ordered
    # by path score. The source tag records which adapter served it (graph:cte / graph:age).
    case GraphStore.rank_list(seed_ids,
           min_weight: @graph_min_weight,
           max_hops: @graph_max_hops,
           fanout: @graph_fanout,
           limit: cpp()
         ) do
      {:ok, results} when results != [] ->
        [{0.8, {:graph, GraphStore.adapter_name()}, Enum.map(results, & &1.memory_id)}]

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

  # RRF variant that also returns, per memory id, the ranked source contributions (source tag,
  # rank within that source's list, and this source's share of the fused score). Used only by
  # preview/3; the normal rrf/2 return shape is unchanged.
  defp rrf_detailed(rank_lists, k) do
    {scores, contribs} =
      Enum.reduce(rank_lists, {%{}, %{}}, fn {weight, src, ids}, acc ->
        tag = source_tag(src)

        ids
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {id, idx}, {sc, co} ->
          share = weight / (k + idx + 1)
          entry = %{source: tag, rank: idx + 1, score: share}
          {Map.update(sc, id, share, &(&1 + share)), Map.update(co, id, [entry], &[entry | &1])}
        end)
      end)

    fused = Enum.sort_by(scores, fn {_id, s} -> -s end)
    contribs = Map.new(contribs, fn {id, list} -> {id, Enum.sort_by(list, &(-&1.score))} end)
    {fused, contribs}
  end

  defp source_tag({a, b}), do: "#{a}:#{b}"
  defp source_tag(a), do: "#{a}"

  # mood-anchored emotional rank list (preview): rank by L2 to the supplied mood vector. With no
  # mood, falls back to the ambient (Monitor) emotional list used by active/3.
  defp emotional_rank_list_for(owner, nil), do: emotional_rank_list(owner)

  defp emotional_rank_list_for(owner, mood) when is_map(mood) do
    # Pass the full contract mood map as both mood + hormones: build_vector reads VAD from the
    # former and the four hormones from the latter (extra keys are ignored).
    qvec = Pgvector.new(Emotion.build_vector(mood, mood))

    ids =
      base_scope(owner)
      |> order_by([m], asc: l2_distance(m.emotional_embedding, ^qvec), asc: m.id)
      |> limit(^cpp())
      |> select([m], m.id)
      |> Repo.all()

    [{0.45, {:emotional, :vad}, ids}]
  end

  defp apply_vector_weights(lists, %{vector_weights: vw}) when is_map(vw) do
    Enum.map(lists, fn
      {_w, {:weaviate, nv}, ids} -> {Map.get(vw, to_string(nv), 0.7), {:weaviate, nv}, ids}
      other -> other
    end)
  end

  defp apply_vector_weights(lists, _overrides), do: lists

  # Preview override map → keyed by the two knobs we honor (rrf_k, vector_weights). Accepts
  # string- or atom-keyed input (HTTP JSON vs MCP), coercing numeric values.
  defp normalize_overrides(nil), do: %{}

  defp normalize_overrides(o) when is_map(o) do
    Enum.reduce(o, %{}, fn {key, v}, acc ->
      case to_string(key) do
        "rrf_k" ->
          Map.put(acc, :rrf_k, to_num(v))

        "vector_weights" when is_map(v) ->
          Map.put(acc, :vector_weights, Map.new(v, fn {kk, vv} -> {to_string(kk), to_num(vv)} end))

        _ ->
          acc
      end
    end)
  end

  defp to_num(v) when is_number(v), do: v
  defp to_num(v) when is_binary(v), do: (case Float.parse(v) do {f, _} -> f; :error -> 0.0 end)
  defp to_num(_), do: 0.0

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
