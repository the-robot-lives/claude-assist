defmodule Foryou.Schema.Lists.List do
  @moduledoc """
  A List — a named signup collection within a Service (project). `public_slug`
  is globally unique (D13) and is the canonical key the public signup endpoint +
  embeddable widget resolve by. `settings` holds opt-in mode, sender identity,
  preference defaults, and available channels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(newsletter waitlist inquiry contact mixed)
  @statuses ~w(active archived)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "lists" do
    belongs_to :project, Foryou.Schema.Projects.Project, type: Ecto.UUID
    field :slug, :string
    field :public_slug, :string
    field :name, :string
    field :description, :string
    field :kind, :string, default: "newsletter"
    field :settings, :map, default: %{}
    field :status, :string, default: "active"
    has_many :attributes, Foryou.Schema.Lists.ListAttribute
    has_many :signups, Foryou.Schema.Signups.Signup
    timestamps(type: :utc_datetime_usec, inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @slug_format ~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/

  def changeset(list, attrs) do
    list
    |> cast(attrs, [:project_id, :slug, :public_slug, :name, :description, :kind, :settings, :status])
    |> validate_required([:project_id, :slug, :public_slug, :name])
    |> validate_format(:slug, @slug_format,
      message: "must be lowercase alphanumeric with hyphens, no leading/trailing hyphens")
    |> validate_format(:public_slug, @slug_format,
      message: "must be lowercase alphanumeric with hyphens, no leading/trailing hyphens")
    |> validate_inclusion(:kind, @kinds)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug, name: :uq_lists_project_slug)
    |> unique_constraint(:public_slug, name: :uq_lists_public_slug)
    |> foreign_key_constraint(:project_id)
  end
end
