defmodule Iotgo.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo Iotgo.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(Iotgo.Schema.Users.Credentials.UserCredential, Iotgo.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Iotgo.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, Iotgo.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Iotgo.Versioned.Descriptions.DescriptionReference
    field :status, nil,
          {:ecto, Iotgo.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}
    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
