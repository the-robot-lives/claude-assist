defmodule Aifighter.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo Aifighter.Versioned.Descriptions
  @sref "versioned-description"
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  @persistence ecto_store(Aifighter.Schema.Versioned.Descriptions.Description, Aifighter.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
