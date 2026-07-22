defmodule Therobotknows.Schema.Canon.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "tags" do
    field :name, :string
    field :slug, :string

    belongs_to :universe, Therobotknows.Schema.Universe.Universe

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:universe_id, :name, :slug])
    |> validate_required([:universe_id, :name, :slug])
    |> update_change(:slug, &slugify/1)
    |> unique_constraint([:universe_id, :slug])
  end

  def slugify(nil), do: nil

  def slugify(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
