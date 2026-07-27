defmodule Timely.Users.Sessions.UserSession do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Users.Sessions
  @sref "user-session"
  @persistence ecto_store(Timely.Schema.Users.Sessions.UserSession, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: true
    @store name: :user_id
    field :user, nil, Timely.Users.UserReference
    @config auto: true
    @store name: :credential_id
    field :credential, nil, Timely.Users.Credentials.UserCredentialReference

    field :status,
          nil,
          {:ecto, Timely.Schema.Users.Sessions.UserSession.__schema__(:type, :status)}

    field :details, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
