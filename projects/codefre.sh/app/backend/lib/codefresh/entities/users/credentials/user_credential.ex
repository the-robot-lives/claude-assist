defmodule Codefresh.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo Codefresh.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(Codefresh.Schema.Users.Credentials.UserCredential, Codefresh.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Codefresh.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, Codefresh.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Codefresh.Versioned.Descriptions.DescriptionReference
    field :status, nil,
          {:ecto, Codefresh.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}
    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
