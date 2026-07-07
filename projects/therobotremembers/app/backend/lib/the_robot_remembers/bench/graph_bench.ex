defmodule TheRobotRemembers.Bench.GraphBench do
  @moduledoc """
  Phase-C benchmark harness (ADR-013): the recursive-CTE spreading activation that is the live
  recall hot path (`TheRobotRemembers.Memory.Recall`) vs. an Apache AGE variable-length traversal,
  measured on a synthetic association graph at scale. Emits p50/p95/p99 latency per backend so the
  promotion criterion — AGE replaces the CTE for recall only if p99 < 1 s at >=100k / >=1M edges —
  can be evaluated on a realistic edge distribution.

  Self-contained by design:

    * it does **not** depend on `TheRobotRemembers.Memory.GraphMirror` — the AGE projection is
      inlined here (`project_vertices/1`, `project_edges/2`); and
    * it does **not** rely on the `Repo` `after_connect` AGE hook or `AGE_GRAPH_ENABLED` — every
      AGE-touching block checks out one connection and runs `LOAD 'age'` + `search_path` on it
      itself (`with_age/1`).

  ## The two queries
    * **CTE** — copied byte-for-byte from `Memory.Recall`: bidirectional walk over
      `association_edges`, <= 3 hops, `weight >= 0.2`, per-node fan-out capped at the 8 strongest
      edges, cycle-guarded by a path array, path score = product of edge weights, top-K by score.
    * **AGE** — `MATCH p = (s:Memory)-[*1..3]-(m:Memory)` anchored on the seed `ext_id`s, path score
      accumulated with `UNWIND relationships(p)` + `exp(sum(log(r.weight)))` (the UNWIND+aggregate
      form, **not** `reduce()`, for portability), floored at `0.2^3`, top-K by score. AGE's VLE has
      no per-node fan-out cap — that asymmetry is exactly what the benchmark measures.

  ## Usage
      # via the mix task (preferred)
      mix trr.bench.graph --nodes 100000 --edges 500000 --queries 50 --seed-size 40

      # or directly
      %{ids: ids} = GraphBench.seed(nodes: 100_000, edges: 500_000)
      GraphBench.run(ids: ids, queries: 50, seed_size: 40)
      GraphBench.cleanup()

  All synthetic rows carry `owner_agent = "bench"` (Postgres) and a `bench: true` property (AGE) so
  `cleanup/0` removes exactly the bench data and nothing else.

  Requires a database with Apache AGE installed and the `trr_memory` graph provisioned (Liquibase
  031). Seeding CREATEs fresh bench vertices/edges (it does not MERGE): the ext_ids are freshly
  generated so there is nothing to reconcile, and CREATE keeps seeding O(N) at 100k–1M scale where a
  property-map `MERGE (m:Memory {ext_id: …})` would seq-scan the un-indexed match form on every row.
  Re-seeding without an intervening `cleanup/0` therefore duplicates the bench subgraph.
  """
  require Logger
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge}

  @bench_owner "bench"

  # Traversal parameters — mirror `Memory.Recall` so the CTE side is the hot path verbatim.
  @graph_min_weight 0.2
  @graph_max_hops 3
  @graph_fanout 8
  # `candidates_per_path` default in `Memory.Recall` — the top-K both backends return.
  @default_k 50
  # AGE score floor: the weakest still-traversable 3-hop product (0.2^3).
  @score_floor 0.008

  # association_edges.edge_type -> AGE edge label (upper; AGE labels are case-sensitive). Duplicated
  # from GraphMirror so the bench carries no dependency on that (concurrently-edited) module.
  @edge_types [:semantic, :emotional, :temporal, :causal, :co_occurrence, :synthetic, :contextual, :tangent]
  @edge_labels %{
    semantic: "SEMANTIC",
    emotional: "EMOTIONAL",
    temporal: "TEMPORAL",
    causal: "CAUSAL",
    co_occurrence: "CO_OCCURRENCE",
    synthetic: "SYNTHETIC",
    contextual: "CONTEXTUAL",
    tangent: "TANGENT"
  }

  # Fixed 7-d emotional vector — the bench never exercises emotional recall, so one constant vector
  # per memory keeps seeding cheap (the column is NOT NULL).
  @emotional_vec [0.1, 0.0, 0.0, 0.3, 0.2, 0.2, 0.2]

  # Custom dollar-quote tag for the cypher body (avoids collision with a `$$` in a value).
  @dollar "$cypher$"
  @query_timeout 120_000

  # ── seed ─────────────────────────────────────────────────────────
  @doc """
  Generate `nodes` bench memories and `edges` bench `association_edges` (batched `insert_all`),
  then project the `>= #{@graph_min_weight}` edge subset (and every vertex) into the AGE graph.
  Returns `%{ids: [uuid], nodes: n, edges: e}`; `ids` feeds `run/1` without re-querying Postgres.

  Options: `:nodes` (10_000), `:edges` (50_000), `:batch` (2_000).
  """
  def seed(opts \\ []) do
    n = Keyword.get(opts, :nodes, 10_000)
    e = Keyword.get(opts, :edges, 50_000)
    batch = Keyword.get(opts, :batch, 2_000)

    if e > 0 and n < 2 do
      raise ArgumentError, "GraphBench.seed/1 needs at least 2 nodes to build edges"
    end

    now = DateTime.utc_now()
    ts = DateTime.to_iso8601(now)
    vec = Pgvector.new(@emotional_vec)
    ids = for _ <- 1..n//1, do: Ecto.UUID.generate()
    ids_tuple = List.to_tuple(ids)

    with_age(fn ->
      # 1) memory rows
      ids
      |> Stream.chunk_every(batch)
      |> Enum.each(fn chunk ->
        Repo.insert_all(Memory, Enum.map(chunk, &memory_row(&1, vec)), timeout: @query_timeout)
      end)

      # 2) vertices — must exist before edge CREATE MATCHes them by ext_id.
      ids
      |> Stream.chunk_every(batch)
      |> Enum.each(&project_vertices/1)

      # 3) edges — generate → insert into PG → project the >= threshold subset, per batch, so
      #    peak memory stays bounded even at 1M edges.
      ids_tuple
      |> generate_edges(n)
      |> Stream.take(e)
      |> Stream.chunk_every(batch)
      |> Enum.each(fn raw ->
        chunk = Enum.uniq_by(raw, &{&1.src, &1.tgt, &1.edge_type})

        Repo.insert_all(AssociationEdge, Enum.map(chunk, &edge_row(&1, now)),
          on_conflict: :nothing,
          timeout: @query_timeout
        )

        chunk |> Enum.filter(&(&1.weight >= @graph_min_weight)) |> project_edges(ts)
      end)
    end)

    %{ids: ids, nodes: n, edges: e}
  end

  defp memory_row(id, vec) do
    %{
      id: id,
      owner_agent: @bench_owner,
      content: "bench",
      emotional_embedding: vec,
      valence: 0.0,
      arousal: 0.0,
      dominance: 0.0,
      cortisol: 0.0,
      dopamine: 0.0,
      oxytocin: 0.0,
      serotonin: 0.0,
      state: :active
    }
  end

  defp edge_row(e, now) do
    %{
      source_memory_id: e.src,
      target_memory_id: e.tgt,
      weight: e.weight,
      edge_type: e.edge_type,
      reinforcement_count: e.rc,
      last_reinforced_at: now
    }
  end

  # Endless stream of random edges over the id pool (bounded by the caller's `Stream.take/2`).
  defp generate_edges(tuple, n) do
    Stream.repeatedly(fn ->
      a = :rand.uniform(n) - 1
      b = other_index(a, n)

      %{
        src: elem(tuple, a),
        tgt: elem(tuple, b),
        weight: sample_weight(),
        edge_type: Enum.random(@edge_types),
        rc: :rand.uniform(20) - 1
      }
    end)
  end

  defp other_index(a, n) do
    case :rand.uniform(n) - 1 do
      ^a -> other_index(a, n)
      b -> b
    end
  end

  # ~20% of edges are sub-threshold (< 0.2, recall-irrelevant, never mirrored); the rest form a
  # beta-ish bell centered ~0.55 (mass in 0.3–0.7).
  defp sample_weight do
    if :rand.uniform() < 0.20 do
      :rand.uniform() * @graph_min_weight
    else
      Float.round(min(@graph_min_weight + beta_ish() * 0.7, 1.0), 4)
    end
  end

  # Mean of three uniforms → a Beta(2,2)-ish bell around 0.5, no stats dependency.
  defp beta_ish, do: (:rand.uniform() + :rand.uniform() + :rand.uniform()) / 3.0

  # ── AGE projection (inlined; no GraphMirror dependency) ──────────
  defp project_vertices([]), do: :ok

  defp project_vertices(ext_ids) do
    list = Enum.map_join(ext_ids, ", ", &"'#{&1}'")
    run_cypher("UNWIND [#{list}] AS x CREATE (m:Memory {ext_id: x, bench: true})")
  end

  defp project_edges([], _ts), do: :ok

  defp project_edges(edges, ts) do
    edges
    |> Enum.group_by(& &1.edge_type)
    |> Enum.each(fn {type, group} ->
      label = Map.fetch!(@edge_labels, type)

      rows =
        Enum.map_join(group, ", ", fn e ->
          "{s:'#{e.src}', t:'#{e.tgt}', w:#{fmt_float(e.weight)}, rc:#{e.rc}, ts:'#{ts}'}"
        end)

      run_cypher("""
      UNWIND [#{rows}] AS row
      MATCH (a:Memory) WHERE a.ext_id = row.s
      MATCH (b:Memory) WHERE b.ext_id = row.t
      CREATE (a)-[r:#{label}]->(b)
      SET r.weight = row.w, r.reinforcement_count = row.rc, r.last_reinforced_at = row.ts, r.bench = true
      """)
    end)
  end

  # ── run ──────────────────────────────────────────────────────────
  @doc """
  Time `queries` random frontiers — each a set of `seed_size` random bench ids, simulating a
  Weaviate seed frontier — against both backends and print/return per-backend p50/p95/p99.

  Options: `:ids` (the pool from `seed/1`; loaded from PG when omitted), `:queries` (50),
  `:seed_size` (40), `:k` (top-K, #{@default_k}), `:warmup` (min(3, queries), discarded).
  """
  def run(opts \\ []) do
    k = Keyword.get(opts, :k, @default_k)
    queries = Keyword.get(opts, :queries, 50)
    seed_size = Keyword.get(opts, :seed_size, 40)
    warmup = Keyword.get(opts, :warmup, min(3, queries))
    pool = load_pool(Keyword.get(opts, :ids))
    n = tuple_size(pool)

    if n == 0, do: raise("GraphBench.run/1: no bench memories — run seed/1 first")

    with_age(fn ->
      Enum.each(1..warmup//1, fn _ ->
        seeds = sample(pool, n, seed_size)
        _ = run_cte(seeds, k)
        _ = run_age(seeds, k)
      end)

      {cte_us, age_us} =
        Enum.reduce(1..queries//1, {[], []}, fn _, {cs, as} ->
          seeds = sample(pool, n, seed_size)
          {c, _} = :timer.tc(fn -> run_cte(seeds, k) end)
          {a, _} = :timer.tc(fn -> run_age(seeds, k) end)
          {[c | cs], [a | as]}
        end)

      stats = %{
        params: %{nodes: n, queries: queries, seed_size: seed_size, k: k},
        cte: summarize(cte_us),
        age: summarize(age_us)
      }

      print_table(stats)
      stats
    end)
  end

  @doc """
  Run both backends once on `seeds`, returning `{cte_ids, age_ids}` (lists of memory-id strings).
  Prepares the AGE session itself; used by the `:age` smoke test.
  """
  def compare_once(seeds, k \\ @default_k) do
    with_age(fn -> {run_cte(seeds, k), run_age(seeds, k)} end)
  end

  defp run_cte(seeds, k) do
    params = [Enum.join(seeds, ","), @graph_min_weight, @graph_max_hops, k, @graph_fanout]

    case Ecto.Adapters.SQL.query(Repo, cte_sql(), params, timeout: @query_timeout) do
      {:ok, %{rows: rows}} -> Enum.map(rows, fn [id, _pw] -> id end)
      {:error, e} -> raise "GraphBench CTE traversal failed: #{inspect(e)}"
    end
  end

  defp run_age(seeds, k) do
    case Ecto.Adapters.SQL.query(Repo, age_traversal_cypher(seeds, k), [], timeout: @query_timeout) do
      {:ok, %{rows: rows}} -> Enum.map(rows, fn [id, _score] -> unquote_agtype(id) end)
      {:error, e} -> raise "GraphBench AGE traversal failed: #{inspect(e)}"
    end
  end

  # ── query builders (public so tests can inspect the strings without a database) ──
  @doc """
  The recursive-CTE spreading activation, verbatim from `Memory.Recall`. Parameters:
  `$1` seed ids (comma-joined), `$2` min weight, `$3` max hops, `$4` top-K, `$5` per-node fan-out.
  """
  def cte_sql do
    """
    WITH RECURSIVE walk(memory_id, depth, path_weight, path) AS (
      SELECT unnest(string_to_array($1, ',')::uuid[]), 0, 1.0::real, ARRAY[]::uuid[]
      UNION ALL
      SELECT nxt.memory_id, w.depth + 1, w.path_weight * nxt.weight, w.path || w.memory_id
      FROM walk w
      JOIN LATERAL (
        SELECT CASE WHEN e.source_memory_id = w.memory_id THEN e.target_memory_id ELSE e.source_memory_id END AS memory_id,
               e.weight
        FROM association_edges e
        WHERE (e.source_memory_id = w.memory_id OR e.target_memory_id = w.memory_id) AND e.weight >= $2
        ORDER BY e.weight DESC, e.id
        LIMIT $5
      ) nxt ON true
      WHERE w.depth < $3
        AND NOT (nxt.memory_id = ANY(w.path))
    )
    SELECT memory_id::text, MAX(path_weight) AS pw
    FROM walk WHERE depth > 0
    GROUP BY memory_id ORDER BY pw DESC, memory_id LIMIT $4
    """
  end

  @doc """
  The AGE variable-length traversal equivalent: anchor on the seed `ext_id`s, expand 1..#{@graph_max_hops}
  hops across every edge label, accumulate the path-weight product via `UNWIND relationships(p)` +
  `exp(sum(log(r.weight)))` (grouped per path, then max per memory), floor at `#{@score_floor}`,
  return the top-`k` by score.
  """
  def age_traversal_cypher(seed_ids, k) do
    seeds = Enum.map_join(seed_ids, ", ", &"'#{&1}'")

    """
    SELECT * FROM cypher('#{graph()}', #{@dollar}
      MATCH p = (s:Memory)-[*1..#{@graph_max_hops}]-(m:Memory)
      WHERE s.ext_id IN [#{seeds}]
      UNWIND relationships(p) AS r
      WITH m, p, exp(sum(log(r.weight))) AS path_score
      WITH m.ext_id AS id, max(path_score) AS score
      WHERE score >= #{fmt_float(@score_floor)}
      RETURN id, score
      ORDER BY score DESC
      LIMIT #{k}
    #{@dollar}) AS (id agtype, score agtype);
    """
  end

  # ── cleanup ──────────────────────────────────────────────────────
  @doc """
  Remove all bench data: AGE bench vertices (and, via `DETACH DELETE`, their edges), then the
  Postgres bench rows (the FK `ON DELETE CASCADE` drops their `association_edges`). AGE removal is
  best-effort — a database without AGE just logs and skips it. Returns `{:ok, deleted_memories}`.
  """
  def cleanup do
    _ =
      try do
        with_age(fn -> run_cypher("MATCH (m:Memory) WHERE m.bench = true DETACH DELETE m") end)
      rescue
        e -> Logger.warning("[GraphBench] AGE cleanup skipped: #{inspect(e)}")
      end

    {deleted, _} = Repo.delete_all(from(m in Memory, where: m.owner_agent == ^@bench_owner))
    {:ok, deleted}
  end

  # ── AGE session / cypher runner ──────────────────────────────────
  @doc """
  Run `fun` on a single checked-out connection with AGE loaded on it. Self-contained: does not rely
  on the `Repo` `after_connect` hook or `AGE_GRAPH_ENABLED` — `LOAD 'age'` + `search_path` are
  issued here so every subsequent `cypher(...)` on this connection resolves.
  """
  def with_age(fun) when is_function(fun, 0) do
    Repo.checkout(fn ->
      Ecto.Adapters.SQL.query!(Repo, "LOAD 'age'", [])
      Ecto.Adapters.SQL.query!(Repo, ~s(SET search_path = "$user", public, ag_catalog), [])
      fun.()
    end)
  end

  defp run_cypher(inner) do
    sql = "SELECT * FROM cypher('#{graph()}', #{@dollar} #{inner} #{@dollar}) AS (result agtype);"
    Ecto.Adapters.SQL.query!(Repo, sql, [], timeout: @query_timeout)
  end

  defp graph, do: Application.get_env(:the_robot_remembers, :age_graph, [])[:graph] || "trr_memory"

  # ── sampling / pool ──────────────────────────────────────────────
  defp load_pool(nil) do
    Repo.all(from(m in Memory, where: m.owner_agent == ^@bench_owner, select: m.id))
    |> List.to_tuple()
  end

  defp load_pool(list) when is_list(list), do: List.to_tuple(list)
  defp load_pool(tuple) when is_tuple(tuple), do: tuple

  defp sample(pool, n, k), do: take_distinct(pool, n, min(k, n), MapSet.new(), [])

  defp take_distinct(_pool, _n, 0, _seen, acc), do: acc

  defp take_distinct(pool, n, remaining, seen, acc) do
    idx = :rand.uniform(n) - 1

    if MapSet.member?(seen, idx) do
      take_distinct(pool, n, remaining, seen, acc)
    else
      take_distinct(pool, n, remaining - 1, MapSet.put(seen, idx), [elem(pool, idx) | acc])
    end
  end

  # ── stats / formatting ───────────────────────────────────────────
  defp summarize(micros) do
    ms = Enum.map(micros, &(&1 / 1000.0))
    sorted = Enum.sort(ms)

    %{
      count: length(ms),
      p50: percentile(sorted, 50),
      p95: percentile(sorted, 95),
      p99: percentile(sorted, 99),
      mean: mean(ms),
      min: List.first(sorted),
      max: List.last(sorted)
    }
  end

  defp percentile([], _p), do: nil

  defp percentile(sorted, p) do
    n = length(sorted)
    idx = max(0, min(n - 1, round(p / 100 * n) - 1))
    Enum.at(sorted, idx)
  end

  defp mean([]), do: nil
  defp mean(list), do: Enum.sum(list) / length(list)

  defp print_table(%{params: pr, cte: cte, age: age}) do
    IO.puts("""

    -- recall traversal benchmark (ADR-013 Phase C) ---------------------
    nodes=#{pr.nodes}  queries=#{pr.queries}  seed_size=#{pr.seed_size}  top_k=#{pr.k}
    #{String.pad_trailing("backend", 9)}#{Enum.map_join(~w(p50 p95 p99 mean min max), "", &String.pad_leading("#{&1}(ms)", 11))}
    #{stat_row("CTE", cte)}
    #{stat_row("AGE", age)}
    --------------------------------------------------------------------
    """)
  end

  defp stat_row(name, s) do
    String.pad_trailing(name, 9) <>
      Enum.map_join([s.p50, s.p95, s.p99, s.mean, s.min, s.max], "", &String.pad_leading(fmt_ms(&1), 11))
  end

  defp fmt_ms(nil), do: "-"
  defp fmt_ms(v), do: :erlang.float_to_binary(v * 1.0, decimals: 2)

  defp fmt_float(n) when is_integer(n), do: fmt_float(n * 1.0)
  defp fmt_float(n) when is_float(n), do: :erlang.float_to_binary(n, [:short])

  # agtype scalars stringify JSON-quoted (`"uuid"`); strip the surrounding quotes.
  defp unquote_agtype(v) when is_binary(v), do: v |> String.trim() |> String.trim("\"")
  defp unquote_agtype(v), do: v
end
