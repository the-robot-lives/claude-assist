defmodule Iotgo.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo Iotgo.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(Iotgo.Schema.Organizations.Membership, Iotgo.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, Iotgo.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, Iotgo.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
