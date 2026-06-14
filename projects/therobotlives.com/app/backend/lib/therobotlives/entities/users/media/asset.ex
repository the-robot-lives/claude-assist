defmodule Therobotlives.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotlives.Users.Media
  @sref "user-media"
  @persistence ecto_store(Therobotlives.Schema.Users.Media.Asset, Therobotlives.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Therobotlives.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, Therobotlives.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Therobotlives.Versioned.Descriptions.DescriptionReference
    field :media_type, nil,
          {:ecto, Therobotlives.Schema.Users.Media.Asset.__schema__(:type, :media_type)}
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
