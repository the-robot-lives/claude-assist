defmodule Therobotlives.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotlives.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(Therobotlives.Schema.Organizations.Membership, Therobotlives.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, Therobotlives.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, Therobotlives.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
