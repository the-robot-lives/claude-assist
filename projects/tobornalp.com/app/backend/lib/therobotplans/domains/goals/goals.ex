defmodule Therobotplans.Domains.Goals do
  @moduledoc """
  OKRs (objectives + key results + check-ins). Objectives cascade via parent_id
  (company → team → individual → personal); progress rolls up from key results.

  A key result may be **item-backed**: kr_item_links connect a KR to items, and
  when `auto_progress` is true the KR's current_value is computed from the
  weighted completion fraction of its linked items (complete item = its full
  weight applied). Call `recompute_progress/1` (or the `:item_completed` hook)
  after item status changes to keep KRs in sync.
  """

  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.{Objective, KeyResult, KrItemLink, OkrCheckin, Item}

  # ── Objectives ────────────────────────────────────────────────

  def create_objective(attrs) do
    %Objective{} |> Objective.changeset(attrs) |> Repo.insert()
  end

  def get_objective(id) do
    Objective
    |> where([o], o.id == ^id)
    |> preload([:key_results, :checkins])
    |> Repo.one()
  end

  def update_objective(id, attrs) do
    case get_objective(id) do
      nil -> {:error, :not_found}
      obj -> obj |> Objective.changeset(attrs) |> Repo.update()
    end
  end

  def delete_objective(id) do
    case Repo.get(Objective, id) do
      nil -> {:error, :not_found}
      obj -> Repo.delete(obj)
    end
  end

  @doc "Objectives visible to a user: owned by them, or in an org/project they're in."
  def list_objectives(org_id, opts \\ []) do
    Objective
    |> where([o], o.organization_id == ^org_id)
    |> maybe_filter(:owner_id, opts[:owner_id])
    |> maybe_filter(:level, opts[:level])
    |> maybe_filter(:status, opts[:status])
    |> maybe_filter(:project_id, opts[:project_id])
    |> order_by([o], desc: o.inserted_at)
    |> preload([:key_results])
    |> Repo.all()
  end

  # ── Key Results ───────────────────────────────────────────────

  def create_key_result(attrs) do
    %KeyResult{}
    |> KeyResult.changeset(attrs)
    |> Repo.insert()
    |> maybe_recompute()
  end

  def get_key_result(id), do: Repo.get(KeyResult, id)

  def update_key_result(id, attrs) do
    case Repo.get(KeyResult, id) do
      nil -> {:error, :not_found}
      kr -> kr |> KeyResult.manual_changeset(attrs) |> Repo.update() |> maybe_recompute()
    end
  end

  def delete_key_result(id) do
    case Repo.get(KeyResult, id) do
      nil -> {:error, :not_found}
      kr -> Repo.delete(kr)
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
  end

  def unlink_item(kr_id, item_id) do
    case Repo.get_by(KrItemLink, key_result_id: kr_id, item_id: item_id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link) |> tap(fn {:ok, _} -> recompute_progress(kr_id) end)
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

      total = Enum.reduce(links, Decimal.new("0"), &Decimal.add(&2, &1.weight))

      done =
        Enum.reduce(links, Decimal.new("0"), fn l, acc ->
          if MapSet.member?(completed_ids, l.item_id),
            do: Decimal.add(acc, l.weight),
            else: acc
        end)

      # completion fraction × target (higher_better) → current_value on the KR's scale.
      current =
        if Decimal.equal?(total, Decimal.new("0")) do
          Decimal.new("0")
        else
          frac = Decimal.div(done, total)
          Decimal.mult(frac, kr.target_value)
        end

      kr |> Ecto.Changeset.change(current_value: current) |> Repo.update()
    else
      {:ok, kr}
    end
  end

  # Recompute every item-backed KR linked to this item (call on item status change).
  def item_status_changed(item_id) do
    KrItemLink
    |> where([l], l.item_id == ^item_id)
    |> select([l], l.key_result_id)
    |> distinct(true)
    |> Repo.all()
    |> Enum.each(&recompute_progress/1)
  end

  # ── Objective progress (roll-up of KR completion) ─────────────

  @doc "Objective progress 0..1 = mean KR completion fraction."
  def objective_progress(objective_id) do
    krs = list_key_results(objective_id)

    case krs do
      [] ->
        Decimal.new("0")

      _ ->
        fracs =
          Enum.map(krs, fn kr ->
            if Decimal.equal?(kr.target_value, Decimal.new("0")),
              do: Decimal.new("0"),
              else: Decimal.div(kr.current_value, kr.target_value)
          end)

        fracs
        |> Enum.reduce(&Decimal.add/2)
        |> Decimal.div(Decimal.new(to_string(length(krs))))
    end
  end

  # ── Check-ins ─────────────────────────────────────────────────

  def create_checkin(attrs), do: %OkrCheckin{} |> OkrCheckin.changeset(attrs) |> Repo.insert()

  def list_checkins(objective_id) do
    OkrCheckin
    |> where([c], c.objective_id == ^objective_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  # ── Internals ─────────────────────────────────────────────────

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, val), do: where(query, [o], field(o, ^field) == ^val)

  defp maybe_recompute({:ok, %KeyResult{id: id, auto_progress: true}}), do: recompute_progress(id) |> then(fn _ -> {:ok, Repo.get(KeyResult, id)} end)
  defp maybe_recompute(other), do: other
end
