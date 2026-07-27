defmodule Timely.Schema.Users.Media.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "user_media" do
    belongs_to :user, Timely.Schema.Users.User, type: Ecto.UUID
    belongs_to :media, Timely.Schema.Media.Asset, type: Ecto.UUID
    belongs_to :description, Timely.Schema.Versioned.Descriptions.Description, type: Ecto.UUID
    field :media_type, Ecto.Enum, values: [:profile, :cover, :gallery, :other]
    field :settings, :map
    field :deleted_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  # ⟦𓄉𓏊𓉏𓈑⟧ changeset :: auto-generated pointer for public function changeset
  def changeset(user_media, attrs) do
    user_media
    |> cast(attrs, [:user_id, :media_id, :description_id, :media_type, :settings])
    |> validate_required([:user_id, :media_id, :media_type])
  end
end
