defmodule HoloGraph.Users.User do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Users
  @sref "user"
  @persistence ecto_store(HoloGraph.Schema.Users.User, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :user_name, nil, :string
    field :handle, nil, :string

    @config auto: true
    @store name: :name_id
    field :name, nil, HoloGraph.Versioned.Names.NameReference

    @config auto: true
    @store name: :description_id
    field :description, nil, HoloGraph.Versioned.Descriptions.DescriptionReference

    field :email, nil, :string
    field :hashed_password, nil, :string
    field :status, nil, {:ecto, HoloGraph.Schema.Users.User.__schema__(:type, :status)}
    field :mobile_phone, nil, :string
    field :profile_completed_at, nil, :utc_datetime_usec
    field :approved_at, nil, :utc_datetime_usec

    @config auto: false
    @store name: :invite_token_id
    field :invite_token, nil, HoloGraph.Organizations.InviteTokenReference

    @config auto: false
    @store name: :approved_by_user_id
    field :approved_by, nil, HoloGraph.Users.UserReference

    field :verified, nil, :boolean
    field :flagged, nil, :boolean
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
