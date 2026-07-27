defmodule Timely.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo Timely.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(Timely.Schema.Users.Credentials.UserCredential, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Timely.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, Timely.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Timely.Versioned.Descriptions.DescriptionReference

    field :status,
          nil,
          {:ecto, Timely.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}

    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
