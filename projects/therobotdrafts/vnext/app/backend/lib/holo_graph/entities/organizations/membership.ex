defmodule HoloGraph.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(HoloGraph.Schema.Organizations.Membership, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, HoloGraph.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, HoloGraph.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
