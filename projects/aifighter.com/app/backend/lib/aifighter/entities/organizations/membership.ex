defmodule Aifighter.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo Aifighter.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(Aifighter.Schema.Organizations.Membership, Aifighter.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, Aifighter.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, Aifighter.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
