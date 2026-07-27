defmodule Timely.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Users.Media
  @sref "user-media"
  @persistence ecto_store(Timely.Schema.Users.Media.Asset, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, Timely.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, Timely.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, Timely.Versioned.Descriptions.DescriptionReference

    field :media_type,
          nil,
          {:ecto, Timely.Schema.Users.Media.Asset.__schema__(:type, :media_type)}

    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
