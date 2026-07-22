defmodule TheRobotLearns.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Organizations
  @sref "organization"
  @persistence ecto_store(TheRobotLearns.Schema.Organizations.Organization, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :slug, nil, :string
    field :name, nil, :string
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
