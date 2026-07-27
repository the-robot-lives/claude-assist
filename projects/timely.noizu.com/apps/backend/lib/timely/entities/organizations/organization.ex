defmodule Timely.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Organizations
  @sref "organization"
  @persistence ecto_store(Timely.Schema.Organizations.Organization, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :slug, nil, :string
    field :name, nil, :string
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
