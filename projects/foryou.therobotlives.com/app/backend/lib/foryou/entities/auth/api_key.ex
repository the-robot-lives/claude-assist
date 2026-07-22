defmodule Foryou.Auth.ApiKey do
  use Noizu.Entities

  @vsn 1.0
  @repo Foryou.Auth.ApiKeys
  @sref "api-key"
  @persistence ecto_store(Foryou.Schema.Auth.ApiKey, Foryou.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)

    @config auto: true
    @store name: :owner_user_id
    field :owner, nil, Foryou.Users.UserReference

    field :name, nil, :string
    field :key_prefix, nil, :string
    field :scopes, nil, {:ecto, Foryou.Schema.Auth.ApiKey.__schema__(:type, :scopes)}
    field :status, nil, {:ecto, Foryou.Schema.Auth.ApiKey.__schema__(:type, :status)}
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
