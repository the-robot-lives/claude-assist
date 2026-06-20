defmodule TheRobotRemembers.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotRemembers.Versioned.Descriptions
  @sref "versioned-description"
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  @persistence ecto_store(TheRobotRemembers.Schema.Versioned.Descriptions.Description, TheRobotRemembers.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
