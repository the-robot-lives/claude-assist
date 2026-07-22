defmodule TheRobotLearns.Authz.Groups.Group do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Authz.Groups
  @sref "authz-group"
  @persistence ecto_store(TheRobotLearns.Schema.Authz.Group, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :name, nil, :string
    field :display_name, nil, :string
    field :description, nil, :string
    field :is_system, true, :boolean
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
