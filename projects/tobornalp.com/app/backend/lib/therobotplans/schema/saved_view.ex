defmodule Therobotplans.Schema.SavedView do
  @moduledoc """
  A persisted filter/sort/groupBy configuration for a list/board/gantt/calendar
  view. Org-required, project-optional (mirrors items/artifacts scoping).

  Ownership semantics:
    * `owner_user_id` IS NULL  -> shared/org view (visible org-wide in scope).
    * `owner_user_id` = user   -> that user's personal view.
  `config` is opaque jsonb (filters, sort, groupBy, swimlane, column layout);
  the DB never introspects it.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @view_types ~w(list board gantt calendar)
  @entity_types ~w(item)

  schema "saved_views" do
    field :organization_id, :binary_id
    field :project_id, :binary_id
    field :owner_user_id, :binary_id
    field :name, :string
    field :entity_type, :string, default: "item"
    field :view_type, :string, default: "list"
    field :config, :map, default: %{}
    field :is_shared, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for create. Org + name + view_type are required."
  def changeset(saved_view, attrs) do
    saved_view
    |> cast(attrs, [
      :organization_id,
      :project_id,
      :owner_user_id,
      :name,
      :entity_type,
      :view_type,
      :config,
      :is_shared
    ])
    |> validate_required([:organization_id, :name, :view_type])
    |> validate_inclusion(:view_type, @view_types)
    |> validate_inclusion(:entity_type, @entity_types)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:project_id)
    # Backstop for the partial unique index on shared names per scope; only
    # fires server-side when owner_user_id IS NULL. See 044 changelog.
    |> unique_constraint(:name, name: :idx_saved_views_shared_name)
  end

  def view_types, do: @view_types
  def entity_types, do: @entity_types
end
