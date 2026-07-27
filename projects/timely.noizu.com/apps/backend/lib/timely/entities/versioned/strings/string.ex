defmodule Timely.Versioned.Strings.String do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Versioned.Strings
  @sref "versioned-string"
  @persistence ecto_store(Timely.Schema.Versioned.Strings.String, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :content, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
