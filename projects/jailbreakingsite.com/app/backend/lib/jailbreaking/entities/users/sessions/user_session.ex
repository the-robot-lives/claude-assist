defmodule Jailbreaking.Users.Sessions.UserSession do
  use Noizu.Entities

  @vsn 1.0
  @repo Jailbreaking.Users.Sessions
  @sref "user-session"
  @persistence ecto_store(Jailbreaking.Schema.Users.Sessions.UserSession, Jailbreaking.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: true
    @store name: :user_id
    field :user, nil, Jailbreaking.Users.UserReference
    @config auto: true
    @store name: :credential_id
    field :credential, nil, Jailbreaking.Users.Credentials.UserCredentialReference
    field :status, nil,
          {:ecto, Jailbreaking.Schema.Users.Sessions.UserSession.__schema__(:type, :status)}
    field :details, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
