defmodule HoloGraph.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Organizations
  @sref "organization"
  @persistence ecto_store(HoloGraph.Schema.Organizations.Organization, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :slug, nil, :string
    field :name, nil, :string
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
