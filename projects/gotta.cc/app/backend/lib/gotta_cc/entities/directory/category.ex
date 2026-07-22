defmodule GottaCc.Directory.Category do
  use Noizu.Entities

  @vsn 1.0
  @repo GottaCc.Directory
  @sref "directory.category"
  @persistence ecto_store(GottaCc.Schema.Directory.Category, GottaCc.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    id(:uuid)

    field :slug, nil, :string
    field :name, nil, :string
    field :display_order, 0, :integer
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
