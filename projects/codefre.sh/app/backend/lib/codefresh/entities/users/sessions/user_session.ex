defmodule Codefresh.Users.Sessions.UserSession do
  use Noizu.Entities

  @vsn 1.0
  @repo Codefresh.Users.Sessions
  @sref "user-session"
  @persistence ecto_store(Codefresh.Schema.Users.Sessions.UserSession, Codefresh.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: true
    @store name: :user_id
    field :user, nil, Codefresh.Users.UserReference
    @config auto: true
    @store name: :credential_id
    field :credential, nil, Codefresh.Users.Credentials.UserCredentialReference

    field :status,
          nil,
          {:ecto, Codefresh.Schema.Users.Sessions.UserSession.__schema__(:type, :status)}

    field :details, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
