defmodule TheRobotLearns.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Versioned.Descriptions
  @sref "versioned-description"
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour
  @persistence ecto_store(TheRobotLearns.Schema.Versioned.Descriptions.Description, TheRobotLearns.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
