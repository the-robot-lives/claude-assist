defmodule Timely.Versioned.Descriptions.Description do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Versioned.Descriptions
  @sref "versioned-description"
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour
  @persistence ecto_store(Timely.Schema.Versioned.Descriptions.Description, Timely.Repo)
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :body, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
