defmodule TheRobotLearns.Versioned.Strings.String do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Versioned.Strings
  @sref "versioned-string"
  @persistence ecto_store(TheRobotLearns.Schema.Versioned.Strings.String, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :content, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
