defmodule Therobotplans.Today do
  @moduledoc """
  The unified "what do I do now" surface — `plan/2` aggregates everything
  competing for a user's time into a single view backing the Today screen:

    * items assigned to the user (or due soon) across orgs/projects
    * item-backed key results the user owns (so priorities are visible)
    * the user's active objectives + their progress
    * unread notification count

  This is a read aggregation over the items/goals/notifications domains — it
  owns no table. `user_id` is the authenticated caller; `org_id` scopes to one
  organization (optional — omit to span all the user's orgs).
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.{Item, Objective, KeyResult, KrItemLink}
  alias Therobotplans.Domains.Notifications

  @doc """
  Build the Today plan for `user_id`, optionally scoped to `org_id`.

  Returns:
    * `:assigned` — open items assigned to the user, priority-ordered
    * `:due_soon` — items with a `due_date` custom field or stage-driven due,
      narrowed to those due within the window (default 7 days)
    * `:objectives` — the user's active objectives with progress
    * `:key_results` — item-backed KRs the user owns, with progress
    * `:unread` — unread notification count (per org if scoped)
  """
  def plan(user_id, opts \\ []) do
    org_id = opts[:org_id]
    due_window_days = opts[:due_window_days] || 7

    assigned = assigned_items(user_id, org_id)
    due_soon = due_soon_items(user_id, org_id, due_window_days)
    objectives = active_objectives(user_id, org_id)
    kr_ids = kr_ids_for_user(user_id, org_id)
    key_results = item_backed_krs(kr_ids)
    unread = unread_count(user_id, org_id)

    %{
      user_id: user_id,
      assigned: assigned,
      due_soon: due_soon,
      objectives: objectives,
      key_results: key_results,
      unread_notifications: unread
    }
  end

  defp assigned_items(user_id, org_id) do
    Item
    |> where([i], i.assignee == ^to_string(user_id) and i.status not in ~w(done closed))
    |> scope_org(org_id)
    |> order_by([i],
      asc:
        fragment(
          "CASE ? WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 ELSE 4 END",
          i.priority
        ),
      desc: i.inserted_at
    )
    |> limit(50)
    |> Repo.all()
  end

  defp due_soon_items(user_id, org_id, days) do
    # Items whose custom_fields.due_date falls within the window. The custom_fields
    # column is jsonb; filter server-side on the key. Only assigned + still-open.
    horizon = Date.add(Date.utc_today(), days)

    Item
    |> where([i], i.assignee == ^to_string(user_id) and i.status not in ~w(done closed))
    |> scope_org(org_id)
    |> where([i], fragment("(custom_fields->>'due_date')::date <= ?", ^horizon))
    |> order_by([i], fragment("(custom_fields->>'due_date')::date"))
    |> limit(25)
    |> Repo.all()
  end

  defp active_objectives(user_id, org_id) do
    Objective
    |> where([o], o.owner_id == ^user_id and o.status in ~w(active at_risk off_track))
    |> scope_org_obj(org_id)
    |> order_by([o], desc: o.inserted_at)
    |> limit(20)
    |> Repo.all()
    |> Enum.map(fn o -> Map.put(o, :progress, Therobotplans.Domains.Goals.objective_progress(o.id)) end)
  end

  defp kr_ids_for_user(user_id, _org_id) do
    KeyResult
    |> where([k], k.owner_id == ^user_id and k.auto_progress == true)
    |> select([k], k.id)
    |> Repo.all()
  end

  defp item_backed_krs(kr_ids) do
    KrItemLink
    |> where([l], l.key_result_id in ^kr_ids)
    |> join(:inner, [l], k in KeyResult, on: k.id == l.key_result_id)
    |> select([l, k], %{kr_id: k.id, objective_id: k.objective_id, title: k.title,
                        target: k.target_value, current: k.current_value, item_id: l.item_id})
    |> Repo.all()
  end

  defp unread_count(user_id, nil), do: nil

  defp unread_count(user_id, org_id) when is_binary(org_id) do
    Notifications.count(org_id, to_string(user_id))
  end

  defp scope_org(query, nil), do: query
  defp scope_org(query, org_id), do: where(query, [i], i.organization_id == ^org_id)

  defp scope_org_obj(query, nil), do: query
  defp scope_org_obj(query, org_id), do: where(query, [o], o.organization_id == ^org_id)
end
