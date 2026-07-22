defmodule HoloGraph.Versioned.Names.Name do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Versioned.Names
  @sref "versioned-name"
  @persistence ecto_store(HoloGraph.Schema.Versioned.Names.Name, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :first, nil, :string
    field :middle, [], {:array, :string}
    field :last, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder

  def equal?(_, _), do: false

  def __schema__(:primary_key), do: [:id]
  def __schema__(:redact_fields), do: []
  def __schema__(_), do: true

  def __changeset__() do
    Noizu.Entity.Meta.meta(__MODULE__).changeset_fields
  end
end
