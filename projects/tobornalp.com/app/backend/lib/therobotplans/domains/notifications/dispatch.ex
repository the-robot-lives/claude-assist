defmodule Therobotplans.Domains.Notifications.Dispatch do
  @moduledoc """
  Best-effort fan-out hooks that turn domain events into inbox notifications.

  These are called from the domain contexts (Items.update, Services.Comment.add)
  and MUST never raise into the caller's write path — every public function is
  guarded by `safe/1`. The item domain wires :item_assigned / :item_update;
  the comment service wires :comment. Lean MVP subset of NPL's dispatch.
  """

  require Logger

  alias Therobotplans.Domains.Notifications
  alias Therobotplans.Schema.Item
  alias Therobotplans.Services.Watch
  alias Therobotplans.Repo

  @doc "Fire when an item is assigned to someone (not the reporter)."
  def item_assigned(item) do
    safe(fn ->
      org_id = val(item, :organization_id)
      assignee = val(item, :assignee)
      reporter = val(item, :reporter)

      if org_id && assignee && assignee != reporter do
        notify(%{
          organization_id: org_id,
          project_id: val(item, :project_id),
          recipient: assignee,
          sender: reporter,
          kind: "item_assigned",
          subject_type: "item",
          subject_id: val(item, :id),
          body: val(item, :title),
          payload: %{item_id: val(item, :id), status: val(item, :status)}
        })
      end
    end)
  end

  @doc "Fire on a non-assignment item update — notifies the watchers of the item."
  def item_update(item) do
    safe(fn ->
      org_id = val(item, :organization_id)

      if org_id do
        notify_entity_watchers("item", val(item, :id), val(item, :assignee), org_id,
          project_id: val(item, :project_id),
          sender: val(item, :assignee),
          body: val(item, :title),
          kind: "item_update"
        )
      end
    end)
  end

  @doc "Fire when a comment is added to an entity — notifies its watchers + owner."
  def comment(comment) do
    safe(fn ->
      entity_type = val(comment, :entity_type)
      entity_id = val(comment, :entity_id)
      actor = val(comment, :author) || val(comment, :sender)
      item = load_item(entity_type, entity_id)
      org_id = (item && val(item, :organization_id)) || val(comment, :organization_id)

      if org_id do
        notify_entity_watchers(entity_type, entity_id, actor, org_id,
          project_id: (item && val(item, :project_id)) || val(comment, :project_id),
          sender: actor,
          body: val(comment, :content),
          kind: "comment"
        )
      end
    end)
  end

  # Notify an entity's watchers (+ owner), excluding the actor themselves.
  defp notify_entity_watchers(entity_type, entity_id, actor, org_id, opts) do
    owner =
      case load_item(entity_type, entity_id) do
        %{reporter: r} when is_binary(r) -> r
        %{assignee: a} when is_binary(a) -> a
        _ -> nil
      end

    recipients =
      [owner | Watch.watchers(entity_type, entity_id)]
      |> Enum.reject(&(is_nil(&1) or &1 == actor))
      |> Enum.uniq()

    if recipients != [] do
      notify(
        Map.merge(
          %{
            organization_id: org_id,
            recipients: recipients,
            sender: opts[:sender],
            kind: opts[:kind],
            subject_type: entity_type,
            subject_id: entity_id,
            body: opts[:body]
          },
          Map.take(opts, [:project_id])
        )
      )
    end
  end

  defp notify(attrs), do: Notifications.notify(attrs)

  defp load_item("item", id), do: safe_get(Item, id)
  defp load_item(_, _), do: nil

  defp safe_get(mod, id) do
    Repo.get(mod, id)
  rescue
    _ -> nil
  end

  defp val(map, key) when is_map(map), do: Map.get(map, key)
  defp val(_, _), do: nil

  defp safe(fun) do
    fun.()
    :ok
  rescue
    e ->
      Logger.warning("[Notifications.Dispatch] hook error: #{inspect(e)}")
      :error
  catch
    kind, reason ->
      Logger.warning("[Notifications.Dispatch] hook #{kind}: #{inspect(reason)}")
      :error
  end
end
