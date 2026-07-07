defmodule TheRobotRemembers.Memory.GraphMirror do
  @moduledoc """
  Projects the association graph (`memories` + `association_edges`) into Apache AGE (Phase A).

  **AGE is a projection, not the source of truth.** Postgres remains authoritative; the AGE graph
  can be dropped and rebuilt from PG at any time (`backfill/0`). Recall's recursive-CTE hot path
  (`Memory.Recall`) is untouched — this layer exists so future graph-native traversals can be
  benchmarked against the CTE (Phase C) without disturbing the live read path.

  ## What is mirrored
    * A `Memory` vertex per `memories` row, keyed by `ext_id` = the memory's uuid, carrying
      `owner_agent`.
    * A typed edge per `association_edges` row **with `weight >= min_edge_weight`** (default 0.2,
      matching the partial indexes on `association_edges`). Below that threshold the edge is removed
      from AGE. Direction is preserved (source → target).

  ## Cypher construction (why we interpolate)
  AGE's `cypher()` accepts a `$`-parameter map only via `PREPARE`; for this skeleton we interpolate
  validated values directly. Every interpolated value is either a validated UUID (`Ecto.UUID`), a
  clamped float, an integer, an ISO-8601 timestamp, or a cypher-escaped string. The cypher body is
  wrapped in a `$cypher$…$cypher$` dollar-quote (not `$$`) so a property value that happened to
  contain `$$` cannot terminate the literal early.

  ## Indexing note
  The `ext_id` seed index (Liquibase 031) only fires for the `WHERE n.ext_id = '…'` match form, not
  the `{ext_id:'…'}` property-map form (apache/age). Edge upserts therefore `MATCH` both endpoints
  with an explicit `WHERE` clause. Vertex `MERGE` must use the property-map form (MERGE semantics
  require it) and does not hit the index — acceptable at skeleton scale.

  All public ops no-op when the AGE layer is disabled (`enabled?/0`), so callers never need to guard.
  """
  require Logger
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Repo.AGE
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge}
  alias TheRobotRemembers.Workers.GraphMirrorWorker

  # association_edges.edge_type (lower atom) -> AGE edge label (upper; AGE labels are case-sensitive).
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

  # Custom dollar-quote tag — avoids collision with a `$$` sequence in an interpolated property.
  @dollar "$cypher$"

  # ── gating / config ─────────────────────────────────────────────
  @doc "Whether the AGE projection is active (delegates to the runtime flag)."
  def enabled?, do: AGE.enabled?()

  defp graph, do: AGE.graph_name()
  defp min_edge_weight, do: AGE.config()[:min_edge_weight] || 0.2

  # ── enqueue helpers (fire-and-forget; skip entirely when disabled) ──
  @doc """
  Enqueue a re-projection of every edge touching `memory_ids` (and those memories' vertices).
  No-op — and nothing is inserted into Oban — when the AGE layer is disabled.
  """
  def enqueue_sync(memory_ids) when is_list(memory_ids) do
    ids = memory_ids |> Enum.filter(&is_binary/1) |> Enum.uniq()

    if enabled?() and ids != [] do
      safe_enqueue(%{"op" => "sync", "memory_ids" => ids})
    else
      :ok
    end
  end

  def enqueue_sync(_), do: :ok

  @doc "Enqueue a stale-vertex reconcile sweep (see `reconcile/0`)."
  def enqueue_reconcile, do: if(enabled?(), do: safe_enqueue(%{"op" => "reconcile"}), else: :ok)

  @doc "Enqueue a full rebuild of the projection from Postgres (see `backfill/0`)."
  def enqueue_backfill, do: if(enabled?(), do: safe_enqueue(%{"op" => "backfill"}), else: :ok)

  defp safe_enqueue(args) do
    TheRobotRemembers.Jobs.enqueue(GraphMirrorWorker, args)
    :ok
  rescue
    e ->
      Logger.warning("[GraphMirror] enqueue failed: #{inspect(e)}")
      :ok
  catch
    :exit, _ -> :ok
  end

  # ── projection ops (worker-driven) ──────────────────────────────
  @doc """
  Re-project the neighborhood of `ids`: ensure a vertex for every memory and edge endpoint, then
  upsert edges at/above threshold and remove edges that have fallen below it. This is the workhorse
  called after a memory is woven and after a recall reinforcement pass.
  """
  def sync_memories(ids) when is_list(ids) do
    if enabled?() and ids != [] do
      edges = edges_touching(ids)

      endpoint_ids =
        (ids ++ Enum.flat_map(edges, &[&1.source_memory_id, &1.target_memory_id]))
        |> Enum.uniq()

      owners = owners_for(endpoint_ids)

      # 1) vertices first — edge upserts MATCH endpoints by ext_id, so they must exist.
      Enum.each(owners, fn {id, owner} -> do_upsert_vertex(id, owner) end)

      # 2) edges: upsert those meeting the threshold, remove those that dropped below.
      thr = min_edge_weight()

      Enum.each(edges, fn e ->
        if e.weight >= thr and Map.has_key?(owners, e.source_memory_id) and
             Map.has_key?(owners, e.target_memory_id) do
          do_upsert_edge(e)
        else
          do_remove_edge(e.source_memory_id, e.target_memory_id, e.edge_type)
        end
      end)

      :ok
    else
      :ok
    end
  end

  def sync_memories(_), do: :ok

  @doc "Upsert (>= threshold) or remove (< threshold) the AGE projection of one edge."
  def upsert_edge(%AssociationEdge{} = e) do
    cond do
      not enabled?() ->
        :ok

      e.weight >= min_edge_weight() ->
        ensure_vertex(e.source_memory_id)
        ensure_vertex(e.target_memory_id)
        do_upsert_edge(e)

      true ->
        do_remove_edge(e.source_memory_id, e.target_memory_id, e.edge_type)
    end
  end

  @doc "Remove one edge from the projection."
  def remove_edge(%AssociationEdge{} = e),
    do: remove_edge(e.source_memory_id, e.target_memory_id, e.edge_type)

  def remove_edge(src, tgt, edge_type),
    do: if(enabled?(), do: do_remove_edge(src, tgt, edge_type), else: :ok)

  @doc "Upsert one memory's vertex (ext_id + owner_agent)."
  def upsert_memory_vertex(%Memory{} = m),
    do: if(enabled?(), do: do_upsert_vertex(m.id, m.owner_agent), else: :ok)

  def upsert_memory_vertex(id) when is_binary(id) do
    if enabled?(), do: ensure_vertex(id), else: :ok
  end

  @doc """
  Full rebuild from Postgres (system of record): a vertex per memory, then an edge per
  `association_edges` row at/above threshold, batched by id keyset.

  For very large graphs (> ~1M edges) prefer AGEFreighter (bulk COPY into AGE's label tables) over
  this row-by-row MERGE path — MERGE-per-edge is fine for a skeleton but not for millions of rows.
  """
  def backfill(batch_size \\ 500) do
    if enabled?() do
      each_batch(Memory, batch_size, fn m -> do_upsert_vertex(m.id, m.owner_agent) end)
      each_batch(edges_at_threshold(), batch_size, fn e -> do_upsert_edge(e) end)
      :ok
    else
      :ok
    end
  end

  @doc """
  Sweep for divergence Postgres never announced — chiefly memories deleted from PG (ON DELETE
  CASCADE drops their `association_edges`, but AGE is never told). Any AGE `Memory` whose `ext_id`
  no longer exists in `memories` is `DETACH DELETE`d (removing its edges too). Returns `{:ok, n}`
  with the number of stale vertices removed.

  Loads the full id sets on both sides; for very large graphs this should be windowed by owner.
  """
  def reconcile do
    if enabled?() do
      graph_ids = MapSet.new(graph_vertex_ext_ids())
      pg_ids = Repo.all(from(m in Memory, select: m.id)) |> MapSet.new()
      stale = MapSet.difference(graph_ids, pg_ids)
      Enum.each(stale, fn ext_id -> run(vertex_delete_sql(ext_id)) end)
      {:ok, MapSet.size(stale)}
    else
      :ok
    end
  end

  # ── cypher / SQL builders (public for unit tests) ───────────────
  @doc false
  def vertex_sql(ext_id, owner_agent) do
    id = uuid!(ext_id)

    # No RETURN: the write is the point, and AGE cannot cast a returned vertex/edge to text (the
    # app's Postgrex types module has no agtype decoder). A no-RETURN write yields 0 rows.
    cypher_sql(
      "MERGE (m:Memory {ext_id: '#{id}'}) SET m.owner_agent = #{cypher_string(owner_agent)}"
    )
  end

  @doc false
  def edge_upsert_sql(src, tgt, edge_type, weight, reinforcement_count, last_reinforced_at) do
    s = uuid!(src)
    t = uuid!(tgt)
    label = edge_label!(edge_type)
    w = fmt_float(clamp01(weight))
    rc = fmt_int(reinforcement_count)
    ts = cypher_string(fmt_timestamp(last_reinforced_at))

    cypher_sql(
      "MATCH (s:Memory), (t:Memory) WHERE s.ext_id = '#{s}' AND t.ext_id = '#{t}' " <>
        "MERGE (s)-[r:#{label}]->(t) " <>
        "SET r.weight = #{w}, r.reinforcement_count = #{rc}, r.last_reinforced_at = #{ts}"
    )
  end

  @doc false
  def edge_remove_sql(src, tgt, edge_type) do
    s = uuid!(src)
    t = uuid!(tgt)
    label = edge_label!(edge_type)

    cypher_sql(
      "MATCH (s:Memory)-[r:#{label}]->(t:Memory) WHERE s.ext_id = '#{s}' AND t.ext_id = '#{t}' DELETE r"
    )
  end

  @doc false
  def vertex_delete_sql(ext_id) do
    id = uuid!(ext_id)
    cypher_sql("MATCH (m:Memory) WHERE m.ext_id = '#{id}' DETACH DELETE m")
  end

  # ── runners ─────────────────────────────────────────────────────
  defp do_upsert_vertex(id, owner), do: run(vertex_sql(id, owner))

  defp do_upsert_edge(%AssociationEdge{} = e),
    do:
      run(
        edge_upsert_sql(
          e.source_memory_id,
          e.target_memory_id,
          e.edge_type,
          e.weight,
          e.reinforcement_count,
          e.last_reinforced_at
        )
      )

  defp do_remove_edge(src, tgt, type), do: run(edge_remove_sql(src, tgt, type))

  defp ensure_vertex(id) do
    case Repo.get(Memory, id) do
      nil -> :ok
      m -> do_upsert_vertex(m.id, m.owner_agent)
    end
  end

  defp run(sql) do
    case Ecto.Adapters.SQL.query(Repo, sql, []) do
      {:ok, _} ->
        :ok

      {:error, e} ->
        Logger.warning("[GraphMirror] cypher failed: #{inspect(e)}")
        {:error, e}
    end
  end

  # ── PG reads ────────────────────────────────────────────────────
  defp edges_touching(ids) do
    Repo.all(
      from(e in AssociationEdge, where: e.source_memory_id in ^ids or e.target_memory_id in ^ids)
    )
  end

  defp edges_at_threshold do
    thr = min_edge_weight()
    from(e in AssociationEdge, where: e.weight >= ^thr)
  end

  defp owners_for(ids) do
    Repo.all(from(m in Memory, where: m.id in ^ids, select: {m.id, m.owner_agent})) |> Map.new()
  end

  defp graph_vertex_ext_ids do
    sql =
      "SELECT ext_id::text FROM cypher('#{graph()}', #{@dollar} MATCH (m:Memory) RETURN m.ext_id #{@dollar}) AS (ext_id agtype);"

    case Ecto.Adapters.SQL.query(Repo, sql, []) do
      {:ok, %{rows: rows}} -> Enum.map(rows, fn [v] -> unquote_agtype(v) end)
      _ -> []
    end
  end

  # Iterate a queryable in id-keyset batches, applying `fun` to each row (no long-held transaction).
  defp each_batch(queryable, batch, fun, cursor \\ nil) do
    rows =
      queryable
      |> then(fn q -> if cursor, do: from(x in q, where: x.id > ^cursor), else: q end)
      |> order_by([x], asc: x.id)
      |> limit(^batch)
      |> Repo.all()

    case rows do
      [] -> :ok
      _ -> Enum.each(rows, fun) && each_batch(queryable, batch, fun, List.last(rows).id)
    end
  end

  # ── formatting / validation ─────────────────────────────────────
  # Two things make this decode cleanly against a live AGE (the app's Postgrex types module has no
  # agtype decoder): (1) the outer SELECT casts to ::text, so the *result column type* Postgrex must
  # describe is text, not agtype (an agtype column fails at prepare regardless of row count); and
  # (2) every GraphMirror op is a write with no RETURN, so cypher() yields 0 rows and result::text is
  # never evaluated — which matters because AGE cannot stringify a vertex/edge object anyway.
  defp cypher_sql(inner),
    do: "SELECT result::text FROM cypher('#{graph()}', #{@dollar} #{inner} #{@dollar}) AS (result agtype);"

  defp uuid!(id) do
    case Ecto.UUID.cast(id) do
      {:ok, u} -> u
      :error -> raise ArgumentError, "GraphMirror: invalid UUID #{inspect(id)}"
    end
  end

  defp edge_label!(type) when is_atom(type),
    do: Map.get(@edge_labels, type) || raise(ArgumentError, "GraphMirror: unknown edge_type #{inspect(type)}")

  defp edge_label!(type) when is_binary(type) do
    case Enum.find(@edge_labels, fn {k, _} -> Atom.to_string(k) == type end) do
      {_k, label} -> label
      nil -> raise ArgumentError, "GraphMirror: unknown edge_type #{inspect(type)}"
    end
  end

  # Single-quoted cypher string literal with backslash-escaping of `\` and `'`.
  defp cypher_string(s) do
    esc =
      s
      |> to_string()
      |> String.replace("\\", "\\\\")
      |> String.replace("'", "\\'")

    "'" <> esc <> "'"
  end

  defp clamp01(w) when is_number(w), do: w |> max(0.0) |> min(1.0)

  defp fmt_float(n) when is_integer(n), do: fmt_float(n * 1.0)
  defp fmt_float(n) when is_float(n), do: :erlang.float_to_binary(n, [:short])

  defp fmt_int(n) when is_integer(n), do: Integer.to_string(n)
  defp fmt_int(n) when is_float(n), do: Integer.to_string(trunc(n))
  defp fmt_int(_), do: "0"

  defp fmt_timestamp(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp fmt_timestamp(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp fmt_timestamp(s) when is_binary(s), do: s
  defp fmt_timestamp(_), do: DateTime.to_iso8601(DateTime.utc_now())

  # agtype scalars stringify JSON-quoted (`"uuid"`); strip the surrounding quotes.
  defp unquote_agtype(nil), do: nil
  defp unquote_agtype(v) when is_binary(v), do: v |> String.trim() |> String.trim("\"")
end
