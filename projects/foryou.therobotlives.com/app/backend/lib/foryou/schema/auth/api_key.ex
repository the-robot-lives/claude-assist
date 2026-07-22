defmodule Foryou.Schema.Auth.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "api_keys" do
    belongs_to :owner, Foryou.Schema.Users.User,
      type: Ecto.UUID,
      foreign_key: :owner_user_id,
      references: :id

    field :name, :string
    field :key_prefix, :string
    field :token_hash, :string
    field :scopes, {:array, :string}, default: []
    field :last_used_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    field :status, :string, default: "active"
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:owner_user_id, :name, :key_prefix, :token_hash, :scopes,
                    :last_used_at, :expires_at, :revoked_at, :status])
    |> validate_required([:owner_user_id, :name, :key_prefix, :token_hash])
    |> unique_constraint(:key_prefix)
  end
end
