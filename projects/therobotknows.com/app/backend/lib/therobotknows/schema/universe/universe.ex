defmodule Therobotknows.Schema.Universe.Universe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "universes" do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :genre, :string
    field :tone, :string
    field :config, :map, default: %{}
    field :status, :string, default: "active"
    field :created_by, Ecto.UUID
    field :deleted_at, :utc_datetime_usec

    has_many :members, Therobotknows.Schema.Universe.Member

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(universe, attrs) do
    universe
    |> cast(attrs, [
      :slug,
      :name,
      :description,
      :genre,
      :tone,
      :config,
      :status,
      :created_by,
      :deleted_at
    ])
    |> validate_required([:name, :slug])
    |> update_change(:slug, &normalize_slug/1)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase alphanumeric with hyphens"
    )
    |> validate_inclusion(:status, ["active", "deleted"])
    |> unique_constraint(:slug)
  end

  def soft_delete_changeset(universe) do
    change(universe, %{
      status: "deleted",
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
  end

  defp normalize_slug(nil), do: nil

  defp normalize_slug(slug) when is_binary(slug) do
    slug
    |> String.downcase()
    |> String.trim()
  end
end
