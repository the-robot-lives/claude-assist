defmodule DesigningDerobot.Versioned.Strings.String do
  use Noizu.Entities

  @vsn 1.0
  @repo DesigningDerobot.Versioned.Strings
  @sref "versioned-string"
  @persistence ecto_store(DesigningDerobot.Schema.Versioned.Strings.String, DesigningDerobot.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :content, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
