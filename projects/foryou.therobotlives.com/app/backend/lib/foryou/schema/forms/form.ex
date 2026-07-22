defmodule Foryou.Schema.Forms.Form do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "forms" do
    belongs_to :organization, Foryou.Schema.Organizations.Organization, type: Ecto.UUID
    field :slug, :string
    field :name, :string
    field :status, :string, default: "draft"
    # denormalized current definition (form_versions keeps history)
    field :definition, :map, default: %{}
    field :current_version_id, Ecto.UUID
    field :settings, :map, default: %{}
    field :deleted_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:organization_id, :slug, :name, :status, :definition,
                    :current_version_id, :settings])
    |> validate_required([:slug, :name])
    |> unique_constraint(:slug, name: :uq_forms_org_slug)
  end
end
