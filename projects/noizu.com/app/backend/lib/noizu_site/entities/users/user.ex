defmodule NoizuSite.Users.User do
  use Noizu.Entities

  @vsn 1.0
  @repo NoizuSite.Users
  @sref "user"
  @persistence ecto_store(NoizuSite.Schema.Users.User, NoizuSite.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :user_name, nil, :string
    field :handle, nil, :string

    @config auto: true
    @store name: :name_id
    field :name, nil, NoizuSite.Versioned.Names.NameReference

    @config auto: true
    @store name: :description_id
    field :description, nil, NoizuSite.Versioned.Descriptions.DescriptionReference

    field :email, nil, :string
    field :hashed_password, nil, :string
    field :status, nil, {:ecto, NoizuSite.Schema.Users.User.__schema__(:type, :status)}
    field :verified, nil, :boolean
    field :flagged, nil, :boolean
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
