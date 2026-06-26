defmodule Therobotsdayjob.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotsdayjob.Users.Media
  @sref "user-media"
  @persistence ecto_store(Therobotsdayjob.Schema.Users.Media.Asset, Therobotsdayjob.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Therobotsdayjob.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, Therobotsdayjob.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Therobotsdayjob.Versioned.Descriptions.DescriptionReference
    field :media_type, nil,
          {:ecto, Therobotsdayjob.Schema.Users.Media.Asset.__schema__(:type, :media_type)}
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
