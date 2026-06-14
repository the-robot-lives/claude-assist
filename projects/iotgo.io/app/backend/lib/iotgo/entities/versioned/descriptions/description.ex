defmodule Iotgo.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo Iotgo.Versioned.Descriptions
  @sref "versioned-description"
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  @persistence ecto_store(Iotgo.Schema.Versioned.Descriptions.Description, Iotgo.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
