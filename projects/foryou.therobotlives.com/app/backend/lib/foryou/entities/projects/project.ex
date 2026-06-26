defmodule Foryou.Projects.Project do
  use Noizu.Entities

  @vsn 1.0
  @repo Foryou.Projects
  @sref "project"
  @persistence ecto_store(Foryou.Schema.Projects.Project, Foryou.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    id(:uuid)

    @config auto: false
    @store name: :organization_id
    field :organization, nil, Foryou.Organizations.OrganizationReference

    field :name, nil, :string
    field :slug, nil, :string
    field :description, nil, :string
    field :settings, %{}, :map
    field :status, "active", :string
    field :archived_at, nil, :utc_datetime_usec
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
