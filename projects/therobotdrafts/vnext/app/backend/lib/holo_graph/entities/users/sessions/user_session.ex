defmodule HoloGraph.Users.Sessions.UserSession do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Users.Sessions
  @sref "user-session"
  @persistence ecto_store(HoloGraph.Schema.Users.Sessions.UserSession, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: true
    @store name: :user_id
    field :user, nil, HoloGraph.Users.UserReference
    @config auto: true
    @store name: :credential_id
    field :credential, nil, HoloGraph.Users.Credentials.UserCredentialReference

    field :status,
          nil,
          {:ecto, HoloGraph.Schema.Users.Sessions.UserSession.__schema__(:type, :status)}

    field :details, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
