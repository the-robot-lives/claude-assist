defmodule Codefresh.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo Codefresh.Organizations
  @sref "organization"
  @persistence ecto_store(Codefresh.Schema.Organizations.Organization, Codefresh.Repo)
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
