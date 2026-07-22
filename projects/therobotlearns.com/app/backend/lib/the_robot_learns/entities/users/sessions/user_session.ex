defmodule TheRobotLearns.Users.Sessions.UserSession do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Users.Sessions
  @sref "user-session"
  @persistence ecto_store(TheRobotLearns.Schema.Users.Sessions.UserSession, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: true
    @store name: :user_id
    field :user, nil, TheRobotLearns.Users.UserReference
    @config auto: true
    @store name: :credential_id
    field :credential, nil, TheRobotLearns.Users.Credentials.UserCredentialReference

    field :status,
          nil,
          {:ecto, TheRobotLearns.Schema.Users.Sessions.UserSession.__schema__(:type, :status)}

    field :details, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
