defmodule HoloGraph.Versioned.Strings.String do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Versioned.Strings
  @sref "versioned-string"
  @persistence ecto_store(HoloGraph.Schema.Versioned.Strings.String, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :content, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
