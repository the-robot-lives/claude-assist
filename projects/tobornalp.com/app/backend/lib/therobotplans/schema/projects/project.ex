defmodule Therobotplans.Schema.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "projects" do
    belongs_to :organization, Therobotplans.Schema.Organizations.Organization, type: Ecto.UUID
    field :name, :string
    field :slug, :string
    field :description, :string
    field :settings, :map, default: %{}
    field :status, :string, default: "active"
    # Human-key prefix for project items (e.g. "TRP-023"). Nullable; auto-derived
    # from slug, overridable. Added by changelog 028a.
    field :key_prefix, :string

    belongs_to :created_by_user, Therobotplans.Schema.Users.User,
      type: Ecto.UUID,
      foreign_key: :created_by

    field :archived_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :organization_id,
      :name,
      :slug,
      :description,
      :settings,
      :status,
      :key_prefix,
      :created_by,
      :archived_at
    ])
    |> validate_required([:organization_id, :name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/,
      message: "must be lowercase alphanumeric with hyphens, no leading/trailing hyphens"
    )
    |> validate_format(:key_prefix, ~r/^[A-Z0-9]{2,16}$/,
      message: "must be 2-16 uppercase alphanumerics"
    )
    |> validate_inclusion(:status, ["active", "archived", "deleted"])
    |> unique_constraint([:organization_id, :slug])
    |> unique_constraint([:organization_id, :key_prefix], name: :idx_projects_org_key_prefix)
  end
end
