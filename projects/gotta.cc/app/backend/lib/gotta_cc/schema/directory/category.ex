defmodule GottaCc.Schema.Directory.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "directory_categories" do
    field :slug, :string
    field :name, :string
    field :display_order, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:slug, :name, :display_order])
    |> validate_required([:slug, :name])
    |> validate_format(:slug, ~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/, message: "must be lowercase alphanumeric with hyphens, no leading/trailing hyphens")
    |> unique_constraint(:slug)
  end
end
