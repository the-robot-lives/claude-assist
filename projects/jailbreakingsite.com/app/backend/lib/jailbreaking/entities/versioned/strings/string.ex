defmodule Jailbreaking.Versioned.Strings.String do
  use Noizu.Entities

  @vsn 1.0
  @repo Jailbreaking.Versioned.Strings
  @sref "versioned-string"
  @persistence ecto_store(Jailbreaking.Schema.Versioned.Strings.String, Jailbreaking.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :content, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
