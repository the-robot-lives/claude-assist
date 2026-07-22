defmodule Foryou.Schema.Forms.FormVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "form_versions" do
    belongs_to :form, Foryou.Schema.Forms.Form, type: Ecto.UUID
    field :version, :integer, default: 1
    field :definition, :map, default: %{}
    field :published_by, Ecto.UUID
    # immutable — no updated_at column
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:form_id, :version, :definition, :published_by])
    |> validate_required([:form_id, :version, :definition])
  end
end
