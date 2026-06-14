defmodule Therobotknows.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotknows.Users.Media
  @sref "user-media"
  @persistence ecto_store(Therobotknows.Schema.Users.Media.Asset, Therobotknows.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Therobotknows.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, Therobotknows.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Therobotknows.Versioned.Descriptions.DescriptionReference
    field :media_type, nil,
          {:ecto, Therobotknows.Schema.Users.Media.Asset.__schema__(:type, :media_type)}
    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
