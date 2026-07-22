defmodule Therobotplans.Domains.Items.ProjectsTodayProvider do
  @moduledoc """
  Today read-model provider for project-derived items — the WS-C `:item` source
  in the Today Read-Model Contract (§2/§3). Surfaces open items that belong to a
  project and are assigned to the user; this is the project half of the current
  `Today.plan/2` `assigned_items` block, lifted into a provider per contract §4.4.

  Inert-but-correct until WS-L lands the aggregator refactor and registers this
  module in the `Therobotplans.Today` `:providers` config (§4.6). Registration
  line (WS-L interface ticket):

      Therobotplans.Domains.Items.ProjectsTodayProvider

  Conforms to the `Therobotplans.Today.Provider` behaviour once WS-L defines it;
  `@behaviour`/`@impl` are intentionally omitted so this module compiles cleanly
  before that behaviour module exists in the tree. The public surface (`source/0`,
  `read/2`) already matches the behaviour, so it activates the moment it's wired.
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Item

  @source :item

  @doc "Stable atom identifying this source; becomes the entries' `:source` (contract §3)."
  def source, do: @source

  @doc """
  Read project-scoped items assigned to `user_id`, mapped to the §2 envelope.

  `opts`:
    * `:org_id`  — nil spans the user's orgs; a binary scopes to one.
    * `:limit`   — max entries (default 25).

  Read-only, side-effect free. Returns `[]` on empty; never raises for no-data.
  """
  def read(user_id, opts \\ []) when is_binary(user_id) do
    org_id = opts[:org_id]
    limit = opts[:limit] || 25
    uid = to_string(user_id)

    Item
    |> where(
      [i],
      i.assignee == ^uid and not is_nil(i.project_id) and i.status not in ~w(done closed)
    )
    |> scope_org(org_id)
    |> order_by([i], asc_nulls_last: i.due_date, asc: i.rank)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&to_entry/1)
  end

  defp scope_org(query, nil), do: query
  defp scope_org(query, org_id), do: where(query, [i], i.organization_id == ^org_id)

  defp to_entry(item) do
    org = item.organization_id
    ref = item.key || item.id

    %{
      id: "#{@source}:#{item.id}",
      source: @source,
      source_ref: %{type: :item, id: item.id},
      kind: :task,
      title: item.title,
      subtitle: item.key,
      link: "/app/#{org}/items/#{ref}",
      due_at: item.due_date,
      status: item.status,
      priority: priority_atom(item.priority),
      weight: nil,
      sort_hint: nil,
      meta: %{project_id: item.project_id, item_key: item.key}
    }
  end

  defp priority_atom(p) when p in ~w(low medium high critical), do: String.to_atom(p)
  defp priority_atom(_), do: nil
end
