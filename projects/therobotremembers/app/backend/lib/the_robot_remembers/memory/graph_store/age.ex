defmodule TheRobotRemembers.Memory.GraphStore.AGE do
  @moduledoc """
  Apache AGE `GraphStore` adapter: the same operations against the `trr_memory` projection via
  `cypher()`. Selected only when the AGE layer is enabled (boot-validated in `GraphStore.validate!/0`).

  Semantics differ from the CTE, which is why `:age` is opt-in and the Phase-C benchmark exists:

    * `rank_list/2` — variable-length traversal `MATCH (s)-[*1..h]-(m)`, path score `exp(sum(log w))`,
      floored at `min_weight^hops`. **No per-node fan-out cap** and **no per-edge weight filter** in
      the VLE, so results are a *superset* of the CTE.
    * `subgraph/2` — a label-filtered `MATCH` determines the owner's node set from the projection; the
      node/edge structs (and the salience-ordered cap) are hydrated from Postgres, since the
      projection carries only `ext_id`/`owner_agent` and edge props, not salience/decay/etc.
    * `neighborhood/3` — VLE `MATCH (s)-[*0..h]-(m)` returning the reachable `ext_id`s.
    * `explain_paths/3` — matches paths to the target set and keeps the best (argmax) path per target.

  `link_candidates/2` is **Dreamer groundwork**: pure AGE pattern queries proposing pairs for future
  causal/synthetic edge generation. No writes, no worker, no LLM here.

  NOTE: the `link_candidates` patterns and `explain_paths` use openCypher pattern predicates
  (`NOT (a)-[:CAUSAL]-(b)`), list comprehensions, `type()`, and map projections — AGE 1.7 features.
  These builders are unit-tested for their string form; live behavior needs verification against an
  AGE database.
  """
  @behaviour TheRobotRemembers.Memory.GraphStore

  require Logger
  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Repo.AGE, as: AgeRepo
  alias TheRobotRemembers.Memory.GraphStore.CTE

  @dollar "$cypher$"
  @query_timeout 30_000

  @edge_labels %{
    "SEMANTIC" => :semantic,
    "EMOTIONAL" => :emotional,
    "TEMPORAL" => :temporal,
    "CAUSAL" => :causal,
    "CO_OCCURRENCE" => :co_occurrence,
    "SYNTHETIC" => :synthetic,
    "CONTEXTUAL" => :contextual,
    "TANGENT" => :tangent
  }

  # ── rank_list ───────────────────────────────────────────────────
  @impl true
  def rank_list([], _opts), do: {:ok, []}

  def rank_list(seed_ids, opts) do
    case run(rank_list_cypher(seed_ids, opts)) do
      {:ok, rows} -> {:ok, Enum.map(rows, fn [id, score] -> %{memory_id: unquote_agtype(id), score: to_float(score)} end)}
      err -> err
    end
  end

  # ── subgraph (node set from AGE, detail hydrated from PG) ────────
  @impl true
  def subgraph(owner_agent, opts) do
    case run(owner_nodes_cypher(owner_agent)) do
      {:ok, rows} ->
        age_ids = Enum.map(rows, fn [id] -> unquote_agtype(id) end)

        ids =
          case opts[:candidate_ids] || :all do
            :all -> age_ids
            list -> MapSet.intersection(MapSet.new(list), MapSet.new(age_ids)) |> MapSet.to_list()
          end

        CTE.subgraph(owner_agent, Keyword.put(opts, :candidate_ids, ids))

      err ->
        err
    end
  end

  # ── neighborhood ────────────────────────────────────────────────
  @impl true
  def neighborhood(seed_id, hops, opts) do
    case run(neighborhood_cypher(seed_id, hops, opts)) do
      {:ok, rows} -> {:ok, Enum.map(rows, fn [id] -> unquote_agtype(id) end)}
      err -> err
    end
  end

  # ── explain_paths ───────────────────────────────────────────────
  @impl true
  def explain_paths([], _targets, _opts), do: {:ok, %{}}
  def explain_paths(_seeds, [], _opts), do: {:ok, %{}}

  def explain_paths(seed_ids, target_ids, opts) do
    case run(explain_cypher(seed_ids, target_ids, opts)) do
      {:ok, rows} ->
        {:ok, best_paths(rows)}

      err ->
        err
    end
  end

  # ── link_candidates (Dreamer groundwork; pure queries, no writes) ──
  @doc """
  Propose association candidates for a future consolidation pass. Returns
  `%{missing_causal: [...], co_recalled: [...]}`, each a list of `%{src, tgt, score}`.
  """
  def link_candidates(owner_agent, opts \\ []) do
    %{
      missing_causal: run_pairs(missing_causal_cypher(owner_agent, opts)),
      co_recalled: run_pairs(co_recalled_cypher(owner_agent, opts))
    }
  end

  # ── cypher builders (public so tests can inspect them without a database) ──
  @doc "Variable-length traversal cypher. Opts: :min_weight, :max_hops, :limit."
  def rank_list_cypher(seed_ids, opts) do
    hops = max_hops(opts)
    floor = fmt_float(Float.round(:math.pow(min_weight(opts), hops), 6))

    wrap(
      """
        MATCH p = (s:Memory)-[*1..#{hops}]-(m:Memory)
        WHERE s.ext_id IN [#{seed_list(seed_ids)}]
        UNWIND relationships(p) AS r
        WITH m, p, exp(sum(log(r.weight))) AS path_score
        WITH m.ext_id AS id, max(path_score) AS score
        WHERE score >= #{floor}
        RETURN id, score
        ORDER BY score DESC
        LIMIT #{limit(opts)}
      """,
      ["id", "score"]
    )
  end

  @doc "All of an owner's Memory vertex ext_ids (label-filtered MATCH)."
  def owner_nodes_cypher(owner_agent) do
    wrap("MATCH (m:Memory) WHERE m.owner_agent = '#{esc(owner_agent)}' RETURN m.ext_id", ["ext_id"])
  end

  @doc "Reachable ext_ids within `hops` of a seed (includes the seed)."
  def neighborhood_cypher(seed_id, hops, _opts) do
    wrap(
      """
        MATCH (s:Memory)-[*0..#{clamp_hops(hops)}]-(m:Memory)
        WHERE s.ext_id = '#{uuid!(seed_id)}'
        RETURN DISTINCT m.ext_id
      """,
      ["ext_id"]
    )
  end

  @doc "Paths from the seed frontier to any target, with node ids + edges + score, per path."
  def explain_cypher(seed_ids, target_ids, opts) do
    hops = max_hops(opts)

    wrap(
      """
        MATCH p = (s:Memory)-[*1..#{hops}]-(m:Memory)
        WHERE s.ext_id IN [#{seed_list(seed_ids)}] AND m.ext_id IN [#{seed_list(target_ids)}]
        WITH m.ext_id AS target,
             [n IN nodes(p) | n.ext_id] AS node_ids,
             [e IN relationships(p) | {type: type(e), weight: e.weight}] AS edges,
             reduce(acc = 1.0, e IN relationships(p) | acc * e.weight) AS score
        RETURN target, node_ids, edges, score
        ORDER BY score DESC
      """,
      ["target", "node_ids", "edges", "score"]
    )
  end

  @doc "Pairs joined by BOTH a temporal and a semantic edge but missing a causal edge (multi-label)."
  def missing_causal_cypher(owner_agent, opts) do
    o = esc(owner_agent)

    wrap(
      """
        MATCH (a:Memory)-[t:TEMPORAL]-(b:Memory), (a)-[sem:SEMANTIC]-(b)
        WHERE a.owner_agent = '#{o}' AND b.owner_agent = '#{o}' AND a.ext_id < b.ext_id
          AND NOT (a)-[:CAUSAL]-(b)
        RETURN DISTINCT a.ext_id AS src, b.ext_id AS tgt, (t.weight + sem.weight) / 2.0 AS score
        ORDER BY score DESC
        LIMIT #{limit(opts)}
      """,
      ["src", "tgt", "score"]
    )
  end

  @doc "Unlinked pairs that share >= `min_shared` strong common neighbors (co-recall candidates)."
  def co_recalled_cypher(owner_agent, opts) do
    o = esc(owner_agent)
    w = fmt_float(min_weight(opts))
    shared = opts[:min_shared] || 2

    wrap(
      """
        MATCH (a:Memory)-[r1]-(x:Memory)-[r2]-(b:Memory)
        WHERE a.owner_agent = '#{o}' AND b.owner_agent = '#{o}' AND a.ext_id < b.ext_id
          AND r1.weight >= #{w} AND r2.weight >= #{w}
          AND NOT (a)-[]-(b)
        WITH a.ext_id AS src, b.ext_id AS tgt, count(DISTINCT x) AS shared
        WHERE shared >= #{shared}
        RETURN src, tgt, shared AS score
        ORDER BY score DESC
        LIMIT #{limit(opts)}
      """,
      ["src", "tgt", "score"]
    )
  end

  # ── path assembly ───────────────────────────────────────────────
  defp best_paths(rows) do
    rows
    |> Enum.reduce(%{}, fn [target, node_ids, edges, score], acc ->
      t = unquote_agtype(target)
      s = to_float(score)
      Map.update(acc, t, {node_ids, edges, s}, fn {_n, _e, best} = cur ->
        if s > best, do: {node_ids, edges, s}, else: cur
      end)
    end)
    |> Map.new(fn {target, {node_ids, edges, _s}} -> {target, hop_chain(node_ids, edges)} end)
  end

  defp hop_chain(node_ids_json, edges_json) do
    node_ids = decode_json(node_ids_json, [])
    edges = decode_edges(edges_json)
    dests = Enum.drop(node_ids, 1)

    edges
    |> Enum.zip(dests)
    |> Enum.map(fn {e, node_id} -> %{edge_type: e.type, weight: e.weight, node_id: node_id} end)
  end

  # ── runners ─────────────────────────────────────────────────────
  defp run(sql) do
    case Ecto.Adapters.SQL.query(Repo, sql, [], timeout: @query_timeout) do
      {:ok, %{rows: rows}} -> {:ok, rows}
      {:error, e} -> Logger.warning("[GraphStore.AGE] query failed: #{inspect(e)}"); {:error, e}
    end
  end

  defp run_pairs(sql) do
    case run(sql) do
      {:ok, rows} ->
        rows
        |> Enum.map(fn [src, tgt, score] ->
          %{src: unquote_agtype(src), tgt: unquote_agtype(tgt), score: to_float(score)}
        end)
        |> Enum.filter(&(valid_uuid?(&1.src) and valid_uuid?(&1.tgt)))

      _ ->
        []
    end
  end

  defp wrap(inner, cols) do
    selects = Enum.map_join(cols, ", ", &"#{&1}::text")
    coldefs = Enum.map_join(cols, ", ", &"#{&1} agtype")
    "SELECT #{selects} FROM cypher('#{graph()}', #{@dollar} #{inner} #{@dollar}) AS (#{coldefs});"
  end

  defp graph, do: AgeRepo.graph_name()
  defp seed_list(ids), do: Enum.map_join(ids, ", ", &"'#{uuid!(&1)}'")

  defp uuid!(id) do
    case Ecto.UUID.cast(id) do
      {:ok, u} -> u
      :error -> raise ArgumentError, "GraphStore.AGE: invalid UUID #{inspect(id)}"
    end
  end

  defp decode_edges(json) do
    json
    |> decode_json([])
    |> Enum.map(fn e -> %{type: Map.get(@edge_labels, e["type"], e["type"]), weight: to_float(e["weight"])} end)
  end

  defp decode_json(nil, default), do: default
  defp decode_json(text, default) when is_binary(text) do
    case Jason.decode(text) do
      {:ok, v} -> v
      _ -> default
    end
  end

  defp esc(s), do: s |> to_string() |> String.replace("\\", "\\\\") |> String.replace("'", "\\'")
  defp valid_uuid?(v), do: match?({:ok, _}, Ecto.UUID.cast(v))

  defp unquote_agtype(nil), do: nil
  defp unquote_agtype(v) when is_binary(v), do: v |> String.trim() |> String.trim("\"")

  defp min_weight(opts), do: opts[:min_weight] || 0.2
  defp max_hops(opts), do: opts[:max_hops] || 3
  defp limit(opts), do: opts[:limit] || 50
  defp clamp_hops(h) when is_integer(h), do: h |> max(1) |> min(3)
  defp clamp_hops(_), do: 2

  defp to_float(nil), do: 0.0
  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v * 1.0

  defp to_float(v) when is_binary(v) do
    case v |> String.trim() |> String.trim("\"") |> Float.parse() do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp fmt_float(n) when is_integer(n), do: fmt_float(n * 1.0)
  defp fmt_float(n) when is_float(n), do: :erlang.float_to_binary(n, [:short])
end
