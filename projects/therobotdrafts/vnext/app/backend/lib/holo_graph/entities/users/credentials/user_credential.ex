defmodule HoloGraph.Users.Credentials.UserCredential do
  use Noizu.Entities
  @vsn 1.0
  @repo HoloGraph.Users.Credentials
  @sref "user-credential"
  @persistence ecto_store(HoloGraph.Schema.Users.Credentials.UserCredential, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, HoloGraph.Users.UserReference
    @config auto: true
    @store name: :auth_provider_id
    field :auth_provider, nil, HoloGraph.Auth.Providers.ProviderReference
    @config auto: true
    @store name: :description_id
    field :description, nil, HoloGraph.Versioned.Descriptions.DescriptionReference

    field :status,
          nil,
          {:ecto, HoloGraph.Schema.Users.Credentials.UserCredential.__schema__(:type, :status)}

    field :settings, %{}, :map
    field :state, %{}, :map
    field :fingerprint, nil, :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
