defmodule TheRobotLearns.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo TheRobotLearns.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(TheRobotLearns.Schema.Users.Credentials.UserCredential, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, TheRobotLearns.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, TheRobotLearns.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, TheRobotLearns.Versioned.Descriptions.DescriptionReference

    field :status,
          nil,
          {:ecto, TheRobotLearns.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}

    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
