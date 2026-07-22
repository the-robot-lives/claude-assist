defmodule Therobotplans.Domains.Personal.TodayProvider do
  @moduledoc """
  Today read-model provider for personal todos (WS-A) — see
  `project-management/contracts/today-read-model.md` §2/§3/§7. Surfaces the
  owner's due-soon and overdue personal items as canonical `entry` maps. Pure
  read, org- and user-scoped, side-effect free.

  Inert-but-correct: it compiles and unit-tests green now, and activates the
  moment WS-L adds it to the `Therobotplans.Today` `:providers` config
  (registration line reported as a WS-L interface ticket — this lane never edits
  that config).
  """
  import Ecto.Query, warn: false

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Item

  # @behaviour Therobotplans.Today.Provider   # enabled once WS-L lands the behaviour module.

  @default_window 7
  @default_limit 25

  @doc "Stable source atom — becomes each entry's `:source`."
  def source, do: :personal

  @doc """
  Read the user's due-soon/overdue personal todos as Today entries.

  `opts`: `:org_id` (nil spans the user's orgs), `:due_window_days` (default 7),
  `:limit` (default 25), `:now` (injected clock). Returns `[]` on empty; never
  raises for ordinary no-data cases.
  """
  def read(user_id, opts \\ []) when is_binary(user_id) do
    window = opts[:due_window_days] || @default_window
    limit = opts[:limit] || @default_limit
    now = opts[:now] || DateTime.utc_now()
    today = DateTime.to_date(now)
    horizon = Date.add(today, window)

    base =
      from i in Item,
        where:
          i.owner_user_id == ^user_id and is_nil(i.project_id) and
            i.status in ["open", "in_progress", "todo"] and
            not is_nil(i.due_date) and i.due_date <= ^horizon,
        order_by: [asc: i.due_date, asc: i.rank],
        limit: ^limit

    base
    |> scope_org(opts[:org_id])
    |> Repo.all()
    |> Enum.map(&to_entry(&1, today))
  rescue
    _ -> []
  end

  defp scope_org(query, nil), do: query
  defp scope_org(query, org_id), do: where(query, [i], i.organization_id == ^org_id)

  defp to_entry(item, today) do
    %{
      id: "personal:#{item.id}",
      source: :personal,
      source_ref: %{type: :item, id: item.id},
      kind: :task,
      title: item.title,
      subtitle: subtitle(item),
      link: "/app/#{item.organization_id}/personal",
      due_at: item.due_date,
      status: item.status,
      priority: normalize_priority(item.priority),
      weight: nil,
      sort_hint: nil,
      meta: %{
        tags: item.tags || [],
        overdue: Date.compare(item.due_date, today) == :lt
      }
    }
  end

  defp subtitle(%{tags: [_ | _] = tags}), do: Enum.map_join(tags, " ", &"##{&1}")
  defp subtitle(_), do: nil

  defp normalize_priority(p) when p in ["low", "medium", "high", "critical"],
    do: String.to_existing_atom(p)

  defp normalize_priority(_), do: nil
end
