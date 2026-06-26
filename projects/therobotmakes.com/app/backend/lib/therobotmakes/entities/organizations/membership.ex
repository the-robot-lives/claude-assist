defmodule Therobotmakes.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotmakes.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(Therobotmakes.Schema.Organizations.Membership, Therobotmakes.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, Therobotmakes.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, Therobotmakes.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
