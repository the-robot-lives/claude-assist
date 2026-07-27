defmodule Timely.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(Timely.Schema.Organizations.Membership, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, Timely.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, Timely.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
