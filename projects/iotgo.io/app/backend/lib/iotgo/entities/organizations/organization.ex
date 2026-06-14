defmodule Iotgo.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo Iotgo.Organizations
  @sref "organization"
  @persistence ecto_store(Iotgo.Schema.Organizations.Organization, Iotgo.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :slug, nil, :string
    field :name, nil, :string
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
