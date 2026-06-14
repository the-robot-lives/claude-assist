defmodule GottaCc.Authz.Groups.Group do
  use Noizu.Entities

  @vsn 1.0
  @repo GottaCc.Authz.Groups
  @sref "authz-group"
  @persistence ecto_store(GottaCc.Schema.Authz.Group, GottaCc.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    id(:uuid)
    field :name, nil, :string
    field :display_name, nil, :string
    field :description, nil, :string
    field :is_system, true, :boolean
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
