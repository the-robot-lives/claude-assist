defmodule Therobotplans.Domains.SavedViews do
  @moduledoc """
  Saved views domain: persists a user's filter/sort/groupBy configuration for a
  list/board/gantt/calendar so it can be recalled and shared.

  Org-required, project-optional (mirrors items/artifacts scoping). A "view" is
  either:

    * shared/org  -> `owner_user_id` IS NULL, visible to every org member in scope.
    * personal    -> `owner_user_id` = some user, only visible to that user.

  `list_views/4` returns the union (shared-in-scope ∪ caller's own). Mutations
  require the caller to own the view OR the view to be shared (org-owned).
  """

  import Ecto.Query, except: [update: 2]

  alias Therobotplans.Repo
  alias Therobotplans.Schema.SavedView

  @doc """
  List views visible to `user_id` within the (org, optional project) scope:
  shared/org views (owner_user_id IS NULL) ∪ the caller's own views.

  Mirrors item_controller scoping: `project_id` nil selects org-level views
  (project_id IS NULL); a given project_id selects that project's views.
  """
  def list_views(org_id, project_id \\ nil, user_id, opts \\ []) do
    base =
      SavedView
      |> where([v], v.organization_id == ^org_id)
      |> where([v], is_nil(v.owner_user_id) or v.owner_user_id == ^user_id)
      |> scope_project(project_id)
      |> maybe_filter(:view_type, opts[:view_type])
      |> maybe_filter(:entity_type, opts[:entity_type])

    base
    |> order_by([v], asc: v.name)
    |> limit(^(opts[:limit] || 100))
    |> offset(^(opts[:offset] || 0))
    |> Repo.all()
  end

  @doc "Fetch a single saved view by id (no scoping; callers enforce scope)."
  def get(id), do: Repo.get(SavedView, id)

  @doc "Create a saved view. `attrs` should carry organization_id + name at least."
  def create(attrs) do
    %SavedView{}
    |> SavedView.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update a saved view from a map/struct of attrs."
  def update(%SavedView{} = view, attrs) do
    view
    |> SavedView.changeset(attrs)
    |> Repo.update()
  end

  @doc "Delete a saved view."
  def delete(%SavedView{} = view) do
    Repo.delete(view)
  end

  @doc "True if `user_id` owns `view` or the view is shared/org-owned."
  def owned_or_shared?(%SavedView{owner_user_id: nil}, _user_id), do: true
  def owned_or_shared?(%SavedView{owner_user_id: uid}, user_id), do: uid == user_id

  # ── helpers ───────────────────────────────────────────────────

  # project_id nil  -> org-level views (project_id IS NULL), mirrors item list.
  # project_id set  -> that project's views exactly.
  defp scope_project(query, nil),
    do: where(query, [v], is_nil(v.project_id))

  defp scope_project(query, project_id),
    do: where(query, [v], v.project_id == ^project_id)

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, _field, ""), do: query
  defp maybe_filter(query, field, val),
    do: where(query, [v], field(v, ^field) == ^val)
end
