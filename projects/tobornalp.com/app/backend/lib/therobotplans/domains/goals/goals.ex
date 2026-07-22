defmodule Therobotplans.Domains.Goals do
  @moduledoc """
  OKRs (objectives + key results + check-ins). Objectives form a true hierarchy via
  `parent_id` (company → team → individual → personal); progress **rolls up** from a
  node's child objectives **and** its own key results under the node's
  `rollup_strategy` (US-069).

  A key result may be **item-backed**: kr_item_links connect a KR to items, and when
  `auto_progress` is true the KR's current_value is computed from the weighted
  completion fraction of its linked items. Call `recompute_progress/1` (or the
  `item_status_changed/1` hook) after item status changes to keep KRs in sync.

  Rolled-up objective progress is **memoized** in `objectives.cached_progress` and
  recomputed **bottom-up** (`recompute_objective_chain/1`, O(depth)) whenever a KR,
  linked item, child, weight, or strategy changes. Hierarchy integrity (no cycles,
  depth ≤ `@max_depth`) is guarded app-side here for a friendly error and by a DB
  trigger (see 043-okr-cycle-depth-trigger.yaml) as the authoritative backstop.
  """

  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Domains.Goals.Rollup
  alias Therobotplans.Schema.{Objective, KeyResult, KrItemLink, OkrCheckin, Item}

  # Max hierarchy depth, root counted as depth 1. Bounds recursive rollup cost and
  # UI nesting; kept in sync with the DB trigger's `ancestor_depth >= 6` check.
  @max_depth 6

  @zero Decimal.new("0")

  def max_depth, do: @max_depth

  # ── Objectives ────────────────────────────────────────────────

  def create_objective(attrs) do
    parent_id = attrs["parent_id"] || attrs[:parent_id]

    with :ok <- create_hierarchy_check(parent_id) do
      %Objective{}
      |> Objective.changeset(attrs)
      |> insert_guarded()
      |> tap_ok(fn o -> safe_recompute(o.parent_id) end)
    end
  end

  def get_objective(id) do
    Objective
    |> where([o], o.id == ^id)
    |> preload([:key_results, :checkins])
    |> Repo.one()
  end

  @doc """
  Update an objective. When `parent_id` changes, cycle + depth are validated
  app-side (friendly `{:error, :cycle}` / `{:error, :max_depth}`) before the write;
  the DB trigger is the authoritative backstop. On success the rollup cache is
  recomputed up both the new and (on reparent) old parent chains.
  """
  def update_objective(id, attrs) do
    case get_objective(id) do
      nil ->
        {:error, :not_found}

      obj ->
        old_parent_id = obj.parent_id
        {reparent?, new_parent_id} = parent_change(attrs, old_parent_id)

        with :ok <- maybe_reparent_check(reparent?, id, new_parent_id) do
          case obj |> Objective.changeset(attrs) |> update_guarded() do
            {:ok, updated} ->
              # A weight/strategy/parent/status change alters this node's contribution
              # to its ancestors — recompute upward from here.
              safe_recompute(updated.id)
              if reparent?, do: safe_recompute(old_parent_id)
              {:ok, updated}

            other ->
              other
          end
        end
    end
  end

  @doc """
  Delete an objective. FR-10: an objective **with children** cannot be deleted
  (`{:error, :has_children}` → 409); the caller must reparent or delete children
  first. A leaf's KRs and check-ins cascade via existing FKs.
  """
  def delete_objective(id) do
    case Repo.get(Objective, id) do
      nil ->
        {:error, :not_found}

      obj ->
        if has_children?(id) do
          {:error, :has_children}
        else
          parent_id = obj.parent_id

          case Repo.delete(obj) do
            {:ok, _} = ok ->
              safe_recompute(parent_id)
              ok

            other ->
              other
          end
        end
    end
  end

  @doc "Objectives in an org, filtered. `:parent_id` → direct children; `:root` → roots only."
  def list_objectives(org_id, opts \\ []) do
    Objective
    |> where([o], o.organization_id == ^org_id)
    |> maybe_filter(:owner_id, opts[:owner_id])
    |> maybe_filter(:level, opts[:level])
    |> maybe_filter(:status, opts[:status])
    |> maybe_filter(:project_id, opts[:project_id])
    |> maybe_filter(:parent_id, opts[:parent_id])
    |> maybe_root(opts[:root])
    |> order_by([o], asc: o.sort_order, desc: o.inserted_at)
    |> preload([:key_results])
    |> Repo.all()
  end

  @doc """
  The org's objective forest — roots with nested descendants, each carrying its
  rolled-up progress. Single query (no N+1); progress served from `cached_progress`
  with on-demand fallback. Returns a list of `%{objective:, progress:, children:}`.
  """
  def objectives_tree(org_id) do
    objs =
      Objective
      |> where([o], o.organization_id == ^org_id)
      |> order_by([o], asc: o.sort_order, asc: o.inserted_at)
      |> preload([:key_results])
      |> Repo.all()

    by_parent = Enum.group_by(objs, & &1.parent_id)

    by_parent
    |> Map.get(nil, [])
    |> Enum.map(&build_tree_node(&1, by_parent))
  end

  defp build_tree_node(obj, by_parent) do
    children = Map.get(by_parent, obj.id, [])

    %{
      objective: obj,
      progress: progress_for(obj),
      children: Enum.map(children, &build_tree_node(&1, by_parent))
    }
  end

  # ── Key Results ───────────────────────────────────────────────

  def create_key_result(attrs) do
    %KeyResult{}
    |> KeyResult.changeset(attrs)
    |> Repo.insert()
    |> maybe_recompute()
    |> tap_ok(fn kr -> safe_recompute(kr.objective_id) end)
  end

  def get_key_result(id), do: Repo.get(KeyResult, id)

  def update_key_result(id, attrs) do
    case Repo.get(KeyResult, id) do
      nil ->
        {:error, :not_found}

      kr ->
        kr
        |> KeyResult.manual_changeset(attrs)
        |> Repo.update()
        |> maybe_recompute()
        |> tap_ok(fn updated -> safe_recompute(updated.objective_id) end)
    end
  end

  def delete_key_result(id) do
    case Repo.get(KeyResult, id) do
      nil ->
        {:error, :not_found}

      kr ->
        case Repo.delete(kr) do
          {:ok, _} = ok ->
            safe_recompute(kr.objective_id)
            ok

          other ->
            other
        end
    end
  end

  def list_key_results(objective_id) do
    KeyResult
    |> where([k], k.objective_id == ^objective_id)
    |> order_by([k], asc: k.inserted_at)
    |> Repo.all()
  end

  # ── KR ↔ item links ───────────────────────────────────────────

  def link_item(kr_id, item_id, weight \\ Decimal.new("1.0")) do
    result =
      Repo.transaction(fn ->
        with {:ok, link} <-
               %KrItemLink{}
               |> KrItemLink.changeset(%{key_result_id: kr_id, item_id: item_id, weight: weight})
               |> Repo.insert() do
          recompute_progress(kr_id)
          link
        else
          {:error, cs} -> Repo.rollback(cs)
        end
      end)

    tap_ok(result, fn _ -> safe_recompute(objective_id_of_kr(kr_id)) end)
  end

  def unlink_item(kr_id, item_id) do
    case Repo.get_by(KrItemLink, key_result_id: kr_id, item_id: item_id) do
      nil ->
        {:error, :not_found}

      link ->
        case Repo.delete(link) do
          {:ok, _} = ok ->
            recompute_progress(kr_id)
            safe_recompute(objective_id_of_kr(kr_id))
            ok

          other ->
            other
        end
    end
  end

  @doc "Recompute an item-backed KR's current_value from the completion of its links."
  def recompute_progress(kr_id) do
    kr = Repo.get(KeyResult, kr_id)

    if kr && kr.auto_progress do
      links =
        KrItemLink
        |> where([l], l.key_result_id == ^kr_id)
        |> Repo.all()

      # An item counts as "complete" when its status is in the done set.
      item_ids = Enum.map(links, & &1.item_id)

      completed_ids =
        Item
        |> where([i], i.id in ^item_ids and i.status in ~w(done closed))
        |> select([i], i.id)
        |> Repo.all()
        |> MapSet.new()

      total = Enum.reduce(links, @zero, &Decimal.add(&2, &1.weight))

      done =
        Enum.reduce(links, @zero, fn l, acc ->
          if MapSet.member?(completed_ids, l.item_id),
            do: Decimal.add(acc, l.weight),
            else: acc
        end)

      # completion fraction × target (higher_better) → current_value on the KR's scale.
      current =
        if Decimal.equal?(total, @zero) do
          @zero
        else
          frac = Decimal.div(done, total)
          Decimal.mult(frac, kr.target_value)
        end

      kr |> Ecto.Changeset.change(current_value: current) |> Repo.update()
    else
      {:ok, kr}
    end
  end

  @doc """
  Recompute every item-backed KR linked to this item, then roll the change up each
  affected objective's ancestor chain. Called from `Items` on status change (the
  existing `items.ex:335` best-effort hook); the chain recompute lives here so the
  items domain needs no change.
  """
  def item_status_changed(item_id) do
    krs =
      KrItemLink
      |> where([l], l.item_id == ^item_id)
      |> join(:inner, [l], k in KeyResult, on: k.id == l.key_result_id)
      |> distinct(true)
      |> select([l, k], {k.id, k.objective_id})
      |> Repo.all()

    Enum.each(krs, fn {kr_id, _} -> recompute_progress(kr_id) end)

    krs
    |> Enum.map(&elem(&1, 1))
    |> Enum.uniq()
    |> Enum.each(&safe_recompute/1)
  end

  # ── Objective progress (hierarchical roll-up) ─────────────────

  @doc """
  Objective progress `0..1` as a Decimal — full on-demand computation over own KRs
  + child objectives under this node's `rollup_strategy` (recurses the subtree,
  depth-bounded). A node with no contributors → `0` (preserves the leaf-with-no-KRs
  behavior). Reads that can tolerate staleness should prefer `progress_for/1`,
  which serves the memoized cache.
  """
  def objective_progress(objective_id) do
    case Repo.get(Objective, objective_id) do
      nil -> @zero
      obj -> compute_node(obj, :full) || @zero
    end
  end

  @doc "Rolled-up progress for a loaded objective: cache first, on-demand fallback."
  def progress_for(%Objective{cached_progress: nil} = obj), do: compute_node(obj, :full) || @zero
  def progress_for(%Objective{cached_progress: cached}), do: cached

  @doc """
  Recompute `cached_progress` bottom-up from `objective_id` to its root — each level
  reuses freshly cached child values, so the walk is O(depth) (bounded by
  `@max_depth`). Best-effort: never raises into a write path.
  """
  def recompute_objective_chain(nil), do: :ok

  def recompute_objective_chain(objective_id) when is_binary(objective_id) do
    case Repo.get(Objective, objective_id) do
      nil -> :ok
      obj -> recompute_up(obj)
    end
  end

  def recompute_objective_chain(_), do: :ok

  defp recompute_up(%Objective{} = obj) do
    _ = recompute_and_cache(obj)

    case obj.parent_id do
      nil -> :ok
      pid -> recompute_objective_chain(pid)
    end
  end

  # Recompute one node from own KRs + children's cached progress, persist the cache.
  defp recompute_and_cache(obj) do
    progress = compute_node(obj, :cached)
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    obj |> Objective.cache_changeset(progress, now) |> Repo.update()
    progress
  end

  # Returns Decimal 0..1, or nil when the node has NO contributors (no data) — the
  # nil signal lets a parent skip a childless child (min_children / weighted_avg).
  # mode: :full recurses children fully; :cached reads children's cached_progress.
  defp compute_node(obj, mode) do
    kr_contribs =
      obj.id
      |> list_key_results()
      |> Enum.map(fn kr ->
        %{frac: Rollup.kr_fraction(kr.current_value, kr.target_value, kr.direction), weight: dec(kr.weight)}
      end)

    children =
      Objective
      |> where([o], o.parent_id == ^obj.id)
      |> Repo.all()

    child_contribs =
      Enum.flat_map(children, fn child ->
        case child_frac(child, mode) do
          nil -> []
          frac -> [%{frac: frac, weight: dec(child.weight)}]
        end
      end)

    case kr_contribs ++ child_contribs do
      [] -> nil
      contribs -> Rollup.resolve(obj, contribs)
    end
  end

  defp child_frac(%Objective{cached_progress: nil} = child, :cached), do: compute_node(child, :full)
  defp child_frac(%Objective{cached_progress: cached}, :cached), do: cached
  defp child_frac(child, :full), do: compute_node(child, :full)

  # ── Check-ins ─────────────────────────────────────────────────

  def create_checkin(attrs), do: %OkrCheckin{} |> OkrCheckin.changeset(attrs) |> Repo.insert()

  def get_checkin(id), do: Repo.get(OkrCheckin, id)

  def delete_checkin(id) do
    case Repo.get(OkrCheckin, id) do
      nil -> {:error, :not_found}
      checkin -> Repo.delete(checkin)
    end
  end

  def list_checkins(objective_id) do
    OkrCheckin
    |> where([c], c.objective_id == ^objective_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  # ── Hierarchy integrity (cycle + depth) ───────────────────────

  @doc """
  Pure hierarchy guard (unit-testable). `ancestor_ids` is the new parent's chain to
  root (new parent first, inclusive); `subtree_height` is the moved node's own
  subtree height (a lone node = 1). Rejects self-parent, direct/transitive cycles,
  and a move whose deepest descendant would exceed `@max_depth`.
  """
  @spec hierarchy_check(binary() | nil, binary() | nil, [binary()], pos_integer()) ::
          :ok | {:error, :cycle} | {:error, :max_depth}
  def hierarchy_check(moved_id, new_parent_id, ancestor_ids, subtree_height) do
    cond do
      is_nil(new_parent_id) -> :ok
      new_parent_id == moved_id -> {:error, :cycle}
      moved_id != nil and moved_id in ancestor_ids -> {:error, :cycle}
      length(ancestor_ids) + subtree_height > @max_depth -> {:error, :max_depth}
      true -> :ok
    end
  end

  # New objective under a parent: only depth matters (a fresh node has no subtree).
  defp create_hierarchy_check(nil), do: :ok

  defp create_hierarchy_check(parent_id) do
    hierarchy_check(nil, parent_id, ancestor_ids(parent_id), 1)
  end

  defp maybe_reparent_check(false, _id, _new_parent_id), do: :ok
  defp maybe_reparent_check(true, _id, nil), do: :ok

  defp maybe_reparent_check(true, id, new_parent_id) do
    hierarchy_check(id, new_parent_id, ancestor_ids(new_parent_id), subtree_height(id))
  end

  # Is a parent_id key present in attrs AND different from the current parent?
  defp parent_change(attrs, old_parent_id) do
    cond do
      Map.has_key?(attrs, "parent_id") -> {norm_uuid(attrs["parent_id"]) != old_parent_id, norm_uuid(attrs["parent_id"])}
      Map.has_key?(attrs, :parent_id) -> {norm_uuid(attrs[:parent_id]) != old_parent_id, norm_uuid(attrs[:parent_id])}
      true -> {false, old_parent_id}
    end
  end

  defp norm_uuid(""), do: nil
  defp norm_uuid(v), do: v

  # Ancestor chain of `id` (id itself first, then up to root), via recursive CTE.
  defp ancestor_ids(nil), do: []

  defp ancestor_ids(id) do
    %{rows: rows} =
      Repo.query!(
        """
        WITH RECURSIVE anc AS (
          SELECT id, parent_id, 1 AS d FROM objectives WHERE id = $1
          UNION ALL
          SELECT o.id, o.parent_id, anc.d + 1
            FROM objectives o JOIN anc ON o.id = anc.parent_id
            WHERE anc.d < 64
        )
        SELECT id FROM anc ORDER BY d
        """,
        [uuid_dump(id)]
      )

    Enum.map(rows, fn [raw] -> Ecto.UUID.load!(raw) end)
  end

  # Height of `id`'s subtree (id alone = 1), via recursive CTE downward.
  defp subtree_height(id) do
    %{rows: [[h]]} =
      Repo.query!(
        """
        WITH RECURSIVE d AS (
          SELECT id, 1 AS depth FROM objectives WHERE id = $1
          UNION ALL
          SELECT o.id, d.depth + 1
            FROM objectives o JOIN d ON o.parent_id = d.id
            WHERE d.depth < 64
        )
        SELECT max(depth) FROM d
        """,
        [uuid_dump(id)]
      )

    h || 1
  end

  defp uuid_dump(id) when is_binary(id) do
    case Ecto.UUID.dump(id) do
      {:ok, bin} -> bin
      :error -> id
    end
  end

  # ── Internals ─────────────────────────────────────────────────

  defp has_children?(id) do
    Repo.exists?(from o in Objective, where: o.parent_id == ^id)
  end

  defp objective_id_of_kr(kr_id) do
    Repo.one(from k in KeyResult, where: k.id == ^kr_id, select: k.objective_id)
  end

  # Best-effort chain recompute — a cache failure must never break the API write.
  defp safe_recompute(nil), do: :ok

  defp safe_recompute(objective_id) do
    recompute_objective_chain(objective_id)
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  # Insert/update wrappers that translate the DB hierarchy trigger's raise into the
  # same tagged tuples the app-side guard returns (defense-in-depth / race backstop).
  defp insert_guarded(changeset) do
    Repo.insert(changeset)
  rescue
    e in Postgrex.Error ->
      case hierarchy_error(e) do
        {:error, _} = tagged -> tagged
        :other -> reraise(e, __STACKTRACE__)
      end
  end

  defp update_guarded(changeset) do
    Repo.update(changeset)
  rescue
    e in Postgrex.Error ->
      case hierarchy_error(e) do
        {:error, _} = tagged -> tagged
        :other -> reraise(e, __STACKTRACE__)
      end
  end

  defp hierarchy_error(%Postgrex.Error{} = e) do
    msg = (e.postgres && e.postgres.message) || ""

    cond do
      String.contains?(msg, "objective_cycle") -> {:error, :cycle}
      String.contains?(msg, "objective_max_depth") -> {:error, :max_depth}
      true -> :other
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, val), do: where(query, [o], field(o, ^field) == ^val)

  defp maybe_root(query, true), do: where(query, [o], is_nil(o.parent_id))
  defp maybe_root(query, "true"), do: where(query, [o], is_nil(o.parent_id))
  defp maybe_root(query, _), do: query

  defp maybe_recompute({:ok, %KeyResult{id: id, auto_progress: true}}),
    do: recompute_progress(id) |> then(fn _ -> {:ok, Repo.get(KeyResult, id)} end)

  defp maybe_recompute(other), do: other

  defp tap_ok({:ok, v} = res, fun) do
    fun.(v)
    res
  end

  defp tap_ok(other, _fun), do: other

  defp dec(nil), do: Decimal.new("1.0")
  defp dec(%Decimal{} = d), do: d
  defp dec(n) when is_integer(n), do: Decimal.new(n)
  defp dec(n) when is_float(n), do: Decimal.from_float(n)
  defp dec(s) when is_binary(s), do: Decimal.new(s)
end
