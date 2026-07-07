defmodule TheRobotRemembers.Memory.GraphStore.CTE do
  @moduledoc """
  Default `GraphStore` adapter: the recursive-CTE / Ecto implementations that recall and the console
  have always run, relocated behind the behaviour **verbatim**. Selecting `:cte` (the default) must
  not change any result, so the SQL here is identical to what lived inline in `Memory.Recall` and
  `Memory.Console`.

    * `rank_list/2`     — the spreading-activation walk (≤ hops, `weight >= min_weight`, per-node
      fan-out cap, cycle-guarded path, path score = product of edge weights, top-K).
    * `subgraph/2`      — the owner-scoped node + edge Ecto fetch (salience-ordered node cap).
    * `neighborhood/3`  — the bidirectional seed walk that yields the reachable memory ids.
    * `explain_paths/3` — the walk restricted to target nodes, reduced to the best path per target.
  """
  @behaviour TheRobotRemembers.Memory.GraphStore

  import Ecto.Query
  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge}

  @query_timeout 30_000
  @recall_states [:active, :consolidating]

  # ── rank_list (recall frontier) ─────────────────────────────────
  @impl true
  def rank_list([], _opts), do: {:ok, []}

  def rank_list(seed_ids, opts) do
    params = [Enum.join(seed_ids, ","), min_weight(opts), max_hops(opts), limit(opts), fanout(opts)]

    case Ecto.Adapters.SQL.query(Repo, rank_list_sql(), params, timeout: @query_timeout) do
      {:ok, %{rows: rows}} -> {:ok, Enum.map(rows, fn [id, pw] -> %{memory_id: id, score: to_float(pw)} end)}
      {:error, e} -> {:error, e}
    end
  end

  # ── subgraph (console graph fetch) ──────────────────────────────
  @impl true
  def subgraph(owner_agent, opts) do
    min_w = min_weight(opts)
    node_limit = opts[:limit] || 500
    compartment = opts[:compartment]
    candidate_ids = opts[:candidate_ids] || :all

    owned =
      base_node_query(owner_agent, compartment)
      |> then(fn q ->
        case candidate_ids do
          :all -> q
          ids -> where(q, [m], m.id in ^ids)
        end
      end)
      |> order_by([m], desc: m.salience, asc: m.id)
      |> limit(^(node_limit + 1))
      |> Repo.all()

    truncated = length(owned) > node_limit
    nodes = Enum.take(owned, node_limit)
    node_ids = Enum.map(nodes, & &1.id)

    edges =
      if node_ids == [] do
        []
      else
        Repo.all(
          from(e in AssociationEdge,
            where:
              e.weight >= ^min_w and e.source_memory_id in ^node_ids and e.target_memory_id in ^node_ids
          )
        )
      end

    {:ok, %{nodes: nodes, edges: edges, truncated: truncated}}
  end

  # ── neighborhood (seed traversal) ───────────────────────────────
  @impl true
  def neighborhood(seed_id, hops, opts) do
    sql = neighborhood_sql()

    case Ecto.Adapters.SQL.query(Repo, sql, [seed_id, min_weight(opts), clamp_hops(hops)], timeout: @query_timeout) do
      {:ok, %{rows: rows}} -> {:ok, Enum.map(rows, fn [id] -> id end)}
      {:error, e} -> {:error, e}
    end
  end

  # ── explain_paths (per-target best path) ────────────────────────
  @impl true
  def explain_paths([], _targets, _opts), do: {:ok, %{}}
  def explain_paths(_seeds, [], _opts), do: {:ok, %{}}

  def explain_paths(seed_ids, target_ids, opts) do
    params = [
      Enum.join(seed_ids, ","),
      min_weight(opts),
      max_hops(opts),
      fanout(opts),
      Enum.join(target_ids, ",")
    ]

    case Ecto.Adapters.SQL.query(Repo, explain_sql(), params, timeout: @query_timeout) do
      {:ok, %{rows: rows}} ->
        {:ok, best_paths(rows)}

      {:error, e} ->
        {:error, e}
    end
  end

  # ── SQL (public so tests can inspect it without a database) ─────
  @doc "The recall spreading-activation CTE. Params: $1 seeds (csv), $2 min_weight, $3 max_hops, $4 limit, $5 fanout."
  def rank_list_sql do
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

  @doc "Bidirectional reachable-id walk from a seed. Params: $1 seed uuid, $2 min_weight, $3 hops."
  def neighborhood_sql do
    """
    WITH RECURSIVE walk(memory_id, depth) AS (
      SELECT $1::text::uuid, 0
      UNION
      SELECT CASE WHEN e.source_memory_id = w.memory_id THEN e.target_memory_id ELSE e.source_memory_id END,
             w.depth + 1
      FROM walk w
      JOIN association_edges e
        ON (e.source_memory_id = w.memory_id OR e.target_memory_id = w.memory_id) AND e.weight >= $2
      WHERE w.depth < $3
    )
    SELECT DISTINCT memory_id::text FROM walk
    """
  end

  @doc "Explanation walk: same activation walk, kept per-path to the requested targets. Params: $1 seeds, $2 min_weight, $3 max_hops, $4 fanout, $5 targets (csv)."
  def explain_sql do
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
        LIMIT $4
      ) nxt ON true
      WHERE w.depth < $3
        AND NOT (nxt.memory_id = ANY(w.path))
    )
    SELECT memory_id::text AS target, (path || memory_id)::text[] AS full_path, path_weight
    FROM walk
    WHERE depth > 0 AND memory_id = ANY(string_to_array($5, ',')::uuid[])
    ORDER BY path_weight DESC
    """
  end

  # ── path assembly ───────────────────────────────────────────────
  # Keep the single best (highest path_weight) path per target, then hydrate its edges into a
  # [{edge_type, weight, node_id}] hop chain.
  defp best_paths(rows) do
    rows
    |> Enum.reduce(%{}, fn [target, nodes, pw], acc ->
      Map.update(acc, target, {nodes, pw}, fn {_n, best} = cur ->
        if pw > best, do: {nodes, pw}, else: cur
      end)
    end)
    |> Map.new(fn {target, {nodes, _pw}} -> {target, hop_chain(nodes)} end)
  end

  defp hop_chain(nodes) when is_list(nodes) do
    nodes
    |> Enum.zip(tl(nodes))
    |> Enum.map(fn {a, b} ->
      case strongest_edge(a, b) do
        nil -> %{edge_type: nil, weight: nil, node_id: b}
        e -> %{edge_type: e.type, weight: e.weight, node_id: b}
      end
    end)
  end

  defp hop_chain(_), do: []

  defp strongest_edge(a, b) do
    Repo.one(
      from(e in AssociationEdge,
        where:
          (e.source_memory_id == ^a and e.target_memory_id == ^b) or
            (e.source_memory_id == ^b and e.target_memory_id == ^a),
        order_by: [desc: e.weight],
        limit: 1,
        select: %{type: e.edge_type, weight: e.weight}
      )
    )
  end

  defp base_node_query(owner_agent, compartment) do
    q = from(m in Memory, where: m.owner_agent == ^owner_agent and m.state in @recall_states)
    if is_binary(compartment) and compartment != "", do: where(q, [m], m.compartment == ^compartment), else: q
  end

  defp min_weight(opts), do: opts[:min_weight] || 0.2
  defp max_hops(opts), do: opts[:max_hops] || 3
  defp fanout(opts), do: opts[:fanout] || 8
  defp limit(opts), do: opts[:limit] || 50
  defp clamp_hops(h) when is_integer(h), do: h |> max(1) |> min(3)
  defp clamp_hops(_), do: 2

  defp to_float(n) when is_float(n), do: n
  defp to_float(n) when is_integer(n), do: n * 1.0
  defp to_float(_), do: 0.0
end
