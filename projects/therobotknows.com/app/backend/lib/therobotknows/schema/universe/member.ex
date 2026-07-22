defmodule Therobotknows.Schema.Universe.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "universe_members" do
    field :role, :string, default: "owner"
    belongs_to :universe, Therobotknows.Schema.Universe.Universe
    belongs_to :user, Therobotknows.Schema.Users.User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:universe_id, :user_id, :role])
    |> validate_required([:universe_id, :user_id, :role])
    |> validate_inclusion(:role, ["owner", "editor", "viewer"])
    |> unique_constraint([:universe_id, :user_id])
  end
end
