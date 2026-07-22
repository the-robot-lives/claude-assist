defmodule Therobotknows.Schema.Canon.EntryVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "entry_versions" do
    field :version, :integer
    field :snapshot, :map, default: %{}
    field :created_by, Ecto.UUID
    field :reason, :string, default: "update"
    field :inserted_at, :utc_datetime_usec

    belongs_to :entry, Therobotknows.Schema.Canon.Entry
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:entry_id, :version, :snapshot, :created_by, :reason, :inserted_at])
    |> validate_required([:entry_id, :version, :snapshot])
    |> unique_constraint([:entry_id, :version])
  end
end
