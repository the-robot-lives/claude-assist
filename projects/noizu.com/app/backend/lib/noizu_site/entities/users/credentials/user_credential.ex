defmodule NoizuSite.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo NoizuSite.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(NoizuSite.Schema.Users.Credentials.UserCredential, NoizuSite.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, NoizuSite.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, NoizuSite.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, NoizuSite.Versioned.Descriptions.DescriptionReference
    field :status, nil,
          {:ecto, NoizuSite.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}
    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
