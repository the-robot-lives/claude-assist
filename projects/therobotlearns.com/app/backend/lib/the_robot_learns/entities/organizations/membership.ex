defmodule TheRobotLearns.Organizations.Membership do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Organizations.Memberships
  @sref "membership"
  @persistence ecto_store(TheRobotLearns.Schema.Organizations.Membership, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :organization_id
    field :organization, nil, TheRobotLearns.Organizations.OrganizationReference
    @config auto: false
    @store name: :user_id
    field :user, nil, TheRobotLearns.Users.UserReference
    field :role, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
