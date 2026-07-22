defmodule TheRobotLearns.Users.Media.Asset do
  use Noizu.Entities

  @vsn 1.0
  @repo TheRobotLearns.Users.Media
  @sref "user-media"
  @persistence ecto_store(TheRobotLearns.Schema.Users.Media.Asset, TheRobotLearns.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    @config auto: false
    @store name: :user_id
    field :user, nil, TheRobotLearns.Users.UserReference
    @config auto: true
    @store name: :media_id
    field :media, nil, TheRobotLearns.Media.AssetReference
    @config auto: true
    @store name: :description_id
    field :description, nil, TheRobotLearns.Versioned.Descriptions.DescriptionReference

    field :media_type,
          nil,
          {:ecto, TheRobotLearns.Schema.Users.Media.Asset.__schema__(:type, :media_type)}

    field :settings, %{}, :map
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use TheRobotLearns.Support.NoizuJasonEncoder
end
