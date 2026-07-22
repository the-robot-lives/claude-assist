defmodule GottaCc.Schema.Directory.SiteClaim do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "directory_site_claims" do
    belongs_to :site, GottaCc.Schema.Directory.Site
    belongs_to :user, GottaCc.Schema.Users.User
    field :method, :string
    field :token, :string
    field :status, :string, default: "pending"
    field :verified_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @methods ["meta_tag", "dns_txt"]
  @statuses ["pending", "verified", "rejected"]

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:site_id, :user_id, :method, :token, :status, :verified_at])
    |> validate_required([:site_id, :user_id, :method, :token, :status])
    |> validate_inclusion(:method, @methods)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:site_id, :user_id],
      name: :directory_site_claims_site_id_user_id_index
    )
  end
end
