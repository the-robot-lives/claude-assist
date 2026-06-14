defmodule Therobotknows.Organizations.Organization do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotknows.Organizations
  @sref "organization"
  @persistence ecto_store(Therobotknows.Schema.Organizations.Organization, Therobotknows.Repo)
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
