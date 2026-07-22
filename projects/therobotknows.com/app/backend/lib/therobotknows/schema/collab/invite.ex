defmodule Therobotknows.Schema.Collab.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "universe_invites" do
    field :email, :string
    field :role, :string, default: "editor"
    field :token, :string
    field :invited_by, Ecto.UUID
    field :accepted_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    field :inserted_at, :utc_datetime_usec

    belongs_to :universe, Therobotknows.Schema.Universe.Universe
  end

  def changeset(inv, attrs) do
    inv
    |> cast(attrs, [
      :universe_id,
      :email,
      :role,
      :token,
      :invited_by,
      :accepted_at,
      :revoked_at,
      :inserted_at
    ])
    |> validate_required([:universe_id, :email, :role, :token])
    |> validate_inclusion(:role, ~w(owner editor viewer))
    |> unique_constraint(:token)
  end
end
