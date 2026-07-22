defmodule Therobotplans.Domains.Personal do
  @moduledoc """
  Personal todos & habits (WS-A) — the lane facade over the shared
  `Domains.Items` substrate. A *personal todo* is an `items` row with
  `item_type = "todo"`, `owner_user_id` set, and `project_id IS NULL`: the same
  polymorphic entity that backs project tasks, just scoped to a user instead of a
  project.

  This context adds three things Items doesn't: owner-scoped listing/grouping
  (overdue/today/upcoming/someday), free-form tag handling, and recurrence
  (materialize-the-next-occurrence-on-completion via `Recurrence` + the
  `item_recurrence_links` side table).
  """
  import Ecto.Query, warn: false

  alias Therobotplans.Repo
  alias Therobotplans.Schema.{Item, RecurrenceRule, ItemRecurrenceLink}
  alias Therobotplans.Domains.Items
  alias Therobotplans.Domains.Personal.Recurrence

  @buckets ~w(overdue today upcoming someday)a

  # ── listing / grouping ────────────────────────────────────────────

  @doc """
  List a user's personal items in an org. Strictly owner-scoped and
  project-less. Supports `:tag` (AND-semantics when a list), `:status`, and `:q`
  (title contains) filters. Default sort: `due_date ASC NULLS LAST, rank ASC`.
  """
  def list_items(org_id, user_id, opts \\ []) do
    base_query(org_id, user_id)
    |> filter_status(opts[:status])
    |> filter_tags(opts[:tag])
    |> filter_q(opts[:q])
    |> order_by([i], asc_nulls_last: i.due_date, asc: i.rank)
    |> Repo.all()
  end

  @doc """
  List grouped into overdue/today/upcoming/someday against "today" in `tz`
  (defaults to UTC). Only *open* items are bucketed as overdue; a done item never
  shows as overdue.
  """
  def list_grouped(org_id, user_id, opts \\ []) do
    tz = opts[:tz]
    today = Recurrence.today_in_zone(tz)
    items = list_items(org_id, user_id, opts)
    group_by_bucket(items, today)
  end

  @doc "Bucket a list of items relative to `today`. Public for the read-model/provider."
  def group_by_bucket(items, %Date{} = today) do
    empty = Map.new(@buckets, &{&1, []})

    grouped =
      Enum.reduce(items, empty, fn item, acc ->
        b = bucket_for(item, today)
        Map.update!(acc, b, &[item | &1])
      end)

    Map.new(grouped, fn {k, v} -> {k, Enum.reverse(v)} end)
  end

  @doc """
  The bucket an item falls in relative to `today`, by due date. Placement is
  date-based (someday/overdue/today/upcoming); the open-aware *overdue flag*
  (`overdue?/2`) is a separate concern — a completed past-due item still buckets
  by date but is not flagged overdue. The grouped view normally lists open items.
  """
  def bucket_for(%{due_date: nil}, _today), do: :someday

  def bucket_for(%{due_date: %Date{} = due}, today) do
    case Date.compare(due, today) do
      :lt -> :overdue
      :eq -> :today
      :gt -> :upcoming
    end
  end

  @doc "Is an open item due before `today` overdue? (the rendered flag)"
  def overdue?(%{due_date: %Date{} = due, status: status}, %Date{} = today),
    do: open?(status) and Date.compare(due, today) == :lt

  def overdue?(_, _), do: false

  defp open?(status), do: status in ["open", "in_progress", "todo", nil]

  defp base_query(org_id, user_id) do
    from i in Item,
      where:
        i.organization_id == ^org_id and i.owner_user_id == ^user_id and is_nil(i.project_id)
  end

  defp filter_status(q, nil), do: q
  defp filter_status(q, ""), do: q
  defp filter_status(q, status), do: where(q, [i], i.status == ^status)

  defp filter_tags(q, nil), do: q
  defp filter_tags(q, []), do: q
  # AND-semantics: the item's tags array must contain ALL requested tags (@>).
  defp filter_tags(q, tags) when is_list(tags),
    do: where(q, [i], fragment("? @> ?", i.tags, ^normalize_tags(tags)))

  defp filter_tags(q, tag), do: filter_tags(q, [tag])

  defp filter_q(q, nil), do: q
  defp filter_q(q, ""), do: q
  defp filter_q(q, text), do: where(q, [i], ilike(i.title, ^"%#{text}%"))

  defp normalize_tags(tags),
    do: tags |> Enum.map(&(&1 |> to_string() |> String.trim() |> String.downcase())) |> Enum.reject(&(&1 == ""))

  @doc """
  Distinct tags used across ALL items in an org (personal + project) — powers
  cross-scope tag autocomplete. GIN-indexed unnest.
  """
  def distinct_tags(org_id) do
    from(i in Item,
      where: i.organization_id == ^org_id,
      select: fragment("DISTINCT unnest(?)", i.tags)
    )
    |> Repo.all()
    |> Enum.sort()
  end

  # ── ownership fetch (controller guard) ────────────────────────────

  @doc """
  Fetch a personal item owned by `user_id`. Returns `{:error, :not_found}` for a
  missing item and `{:error, :forbidden}` for an item owned by someone else —
  the controller maps those to 404/403. Personal items are strictly private to
  their owner, even from org admins.
  """
  def fetch_owned(org_id, item_id, user_id) do
    case Items.get(item_id) do
      nil ->
        {:error, :not_found}

      %Item{organization_id: ^org_id} = item ->
        if item.owner_user_id == user_id, do: {:ok, item}, else: {:error, :forbidden}

      _ ->
        {:error, :not_found}
    end
  end

  # ── create / update ───────────────────────────────────────────────

  @doc """
  Create a personal todo for `user_id`. Forces `project_id: nil`,
  `item_type` default "todo", and `owner_user_id`. When `:recurrence` attrs are
  supplied, requires an anchor (`due_date`) and creates the seed rule + link in
  the same transaction.
  """
  def create_item(org_id, user_id, attrs) do
    recurrence = attrs[:recurrence] || attrs["recurrence"]
    due = attrs[:due_date] || attrs["due_date"]

    if recurrence && is_nil(due) do
      {:error, :recurrence_requires_anchor}
    else
      base = %{
        organization_id: org_id,
        owner_user_id: user_id,
        project_id: nil,
        item_type: attrs[:item_type] || attrs["item_type"] || "todo",
        title: attrs[:title] || attrs["title"],
        description: attrs[:description] || attrs["description"],
        status: attrs[:status] || attrs["status"] || "open",
        priority: attrs[:priority] || attrs["priority"],
        reporter: user_id,
        due_date: due,
        tags: attrs[:tags] || attrs["tags"] || []
      }

      Repo.transaction(fn ->
        case Items.create(base) do
          {:ok, item} ->
            maybe_attach_recurrence(item, recurrence, user_id)
            item

          {:error, cs} ->
            Repo.rollback(cs)
        end
      end)
      |> unwrap_txn()
    end
  end

  @doc """
  Update a personal item. Delegates to `Items.update/3` (which records status/
  priority/etc. events) and additionally records best-effort tag/due_date events
  so the audit trail reflects personal-lane edits.
  """
  def update_item(item, attrs, actor) do
    old = %{tags: item.tags, due_date: item.due_date}

    case Items.update(item.id, attrs, actor: actor) do
      {:ok, updated} ->
        record_personal_events(updated, old, actor)
        {:ok, updated}

      other ->
        other
    end
  end

  # ── completion + recurrence materialization ───────────────────────

  @doc """
  Complete an item; if it drives a recurrence and the series is not exhausted,
  materialize the next occurrence as a new linked item. Returns
  `%{completed: item, next: item | nil}`. Idempotent: completing an already-done
  item is a no-op with `next: nil` (no duplicate successor).
  """
  def complete_item(item, actor) do
    if item.status == "done" do
      {:ok, %{completed: item, next: nil}}
    else
      Repo.transaction(fn ->
        {:ok, completed} = Items.update(item.id, %{status: "done"}, actor: actor)
        next = materialize_next(completed, actor)
        %{completed: completed, next: next}
      end)
      |> unwrap_txn()
    end
  end

  # Materialize the next occurrence if the item has a recurrence link and the
  # series isn't exhausted by `until` (Recurrence) or `count` (series size).
  defp materialize_next(item, actor) do
    with %ItemRecurrenceLink{} = link <- get_link(item.id),
         %RecurrenceRule{} = rule <- Repo.get(RecurrenceRule, link.rule_id),
         seed_id <- link.recurrence_parent_id || item.id,
         false <- count_exhausted?(rule, seed_id),
         anchor <- item.due_date || Recurrence.today_in_zone(rule.timezone),
         {:ok, next_date} <- Recurrence.next_occurrence(rule, anchor) do
      clone = %{
        organization_id: item.organization_id,
        owner_user_id: item.owner_user_id,
        project_id: nil,
        item_type: item.item_type,
        title: item.title,
        description: item.description,
        status: "open",
        priority: item.priority,
        reporter: item.owner_user_id,
        due_date: next_date,
        tags: item.tags || []
      }

      case Items.create(clone) do
        {:ok, new_item} ->
          {:ok, _} = insert_link(new_item.id, rule.id, seed_id)
          record_event(new_item.id, "recurrence", nil, Date.to_iso8601(next_date), actor)
          new_item

        {:error, cs} ->
          Repo.rollback(cs)
      end
    else
      _ -> nil
    end
  end

  defp count_exhausted?(%RecurrenceRule{count: nil}, _seed_id), do: false

  defp count_exhausted?(%RecurrenceRule{count: count}, seed_id) do
    materialized =
      from(l in ItemRecurrenceLink, where: l.recurrence_parent_id == ^seed_id, select: count(l.id))
      |> Repo.one()

    materialized >= count
  end

  # ── recurrence attach / set / clear ───────────────────────────────

  @doc """
  Set (or replace) an item's recurrence from a preset or raw rule fields.
  Requires the item to have an anchor (`due_date`). Creates the rule + seed link,
  replacing any existing link.
  """
  def set_recurrence(item, recurrence, user_id) do
    if is_nil(item.due_date) do
      {:error, :recurrence_requires_anchor}
    else
      Repo.transaction(fn ->
        delete_link(item.id)

        case maybe_attach_recurrence(item, recurrence, user_id) do
          {:ok, _} -> item
          {:error, reason} -> Repo.rollback(reason)
          nil -> Repo.rollback(:invalid_recurrence)
        end
      end)
      |> unwrap_txn()
    end
  end

  @doc "Remove an item's recurrence link (leaves past occurrences intact)."
  def clear_recurrence(item) do
    delete_link(item.id)
    {:ok, item}
  end

  @doc "The rule summary map for an item (or nil), for JSON embedding."
  def recurrence_for(item_id) do
    with %ItemRecurrenceLink{} = link <- get_link(item_id),
         %RecurrenceRule{} = rule <- Repo.get(RecurrenceRule, link.rule_id) do
      %{
        rule_id: rule.id,
        freq: rule.freq,
        interval: rule.interval,
        by_day: rule.by_day,
        by_month_day: rule.by_month_day,
        until: rule.until,
        count: rule.count,
        timezone: rule.timezone,
        roll_on_skip: rule.roll_on_skip,
        recurrence_parent_id: link.recurrence_parent_id
      }
    else
      _ -> nil
    end
  end

  # Build the rule from preset|raw, insert it, and link the item as its own seed.
  # Returns {:ok, link} | {:error, reason} | nil (no recurrence requested).
  defp maybe_attach_recurrence(_item, nil, _user_id), do: nil
  defp maybe_attach_recurrence(_item, "", _user_id), do: nil

  defp maybe_attach_recurrence(item, recurrence, user_id) when is_map(recurrence) do
    with {:ok, rule_attrs} <- build_rule_attrs(recurrence, item.due_date, user_id),
         {:ok, rule} <- %RecurrenceRule{} |> RecurrenceRule.changeset(rule_attrs) |> Repo.insert(),
         {:ok, link} <- insert_link(item.id, rule.id, item.id) do
      {:ok, link}
    end
  end

  defp build_rule_attrs(recurrence, anchor, user_id) do
    preset = recurrence["preset"] || recurrence[:preset]
    tz = recurrence["timezone"] || recurrence[:timezone] || "Etc/UTC"

    cond do
      preset && preset != "custom" ->
        case Recurrence.preset_to_rule(preset, anchor, tz) do
          {:ok, attrs} -> {:ok, Map.merge(attrs, %{owner_user_id: user_id})}
          err -> err
        end

      true ->
        {:ok,
         %{
           owner_user_id: user_id,
           freq: recurrence["freq"] || recurrence[:freq],
           interval: recurrence["interval"] || recurrence[:interval] || 1,
           by_day: recurrence["by_day"] || recurrence[:by_day] || [],
           by_month_day: recurrence["by_month_day"] || recurrence[:by_month_day] || [],
           until: recurrence["until"] || recurrence[:until],
           count: recurrence["count"] || recurrence[:count],
           timezone: tz,
           roll_on_skip: recurrence["roll_on_skip"] || recurrence[:roll_on_skip] || false
         }}
    end
  end

  # ── link table helpers ────────────────────────────────────────────

  defp get_link(item_id), do: Repo.get_by(ItemRecurrenceLink, item_id: item_id)

  defp insert_link(item_id, rule_id, parent_id) do
    %ItemRecurrenceLink{}
    |> ItemRecurrenceLink.changeset(%{
      item_id: item_id,
      rule_id: rule_id,
      recurrence_parent_id: parent_id
    })
    |> Repo.insert()
  end

  defp delete_link(item_id) do
    from(l in ItemRecurrenceLink, where: l.item_id == ^item_id) |> Repo.delete_all()
  end

  # ── best-effort event capture for personal-lane fields ────────────
  # items.ex tracks status/priority/etc.; tags/due_date are personal-lane fields,
  # so we append their change events here. Fully guarded — never raises into the
  # write path (mirrors the items.ex record_item_events guard).
  defp record_personal_events(updated, old, actor) do
    if old.tags != updated.tags,
      do: record_event(updated.id, "tags", inspect(old.tags), inspect(updated.tags), actor)

    if old.due_date != updated.due_date,
      do:
        record_event(
          updated.id,
          "due_date",
          to_string(old.due_date),
          to_string(updated.due_date),
          actor
        )

    :ok
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp record_event(item_id, field, old_value, new_value, actor) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all("item_events", [
      %{
        item_id: Ecto.UUID.dump!(item_id),
        actor: actor,
        field: field,
        old_value: old_value,
        new_value: new_value,
        occurred_at: now
      }
    ])
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp unwrap_txn({:ok, result}), do: {:ok, result}
  defp unwrap_txn({:error, reason}), do: {:error, reason}
end
