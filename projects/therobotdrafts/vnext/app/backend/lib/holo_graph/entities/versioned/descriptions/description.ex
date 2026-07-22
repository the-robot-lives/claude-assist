defmodule HoloGraph.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Versioned.Descriptions
  @sref "versioned-description"
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour
  @persistence ecto_store(HoloGraph.Schema.Versioned.Descriptions.Description, HoloGraph.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
