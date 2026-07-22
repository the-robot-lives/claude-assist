defmodule HoloGraph.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Users.Media
  @sref "user-media"
  @persistence ecto_store(HoloGraph.Schema.Users.Media.Asset, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, HoloGraph.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, HoloGraph.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, HoloGraph.Versioned.Descriptions.DescriptionReference

    field :media_type,
          nil,
          {:ecto, HoloGraph.Schema.Users.Media.Asset.__schema__(:type, :media_type)}

    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
