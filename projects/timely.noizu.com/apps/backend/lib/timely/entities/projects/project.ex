defmodule Timely.Projects.Project do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Projects
  @sref "project"
  @persistence ecto_store(Timely.Schema.Projects.Project, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)

    @config auto: false
    @store name: :organization_id
    field :organization, nil, Timely.Organizations.OrganizationReference

    field :name, nil, :string
    field :slug, nil, :string
    field :description, nil, :string
    field :settings, %{}, :map
    field :status, "active", :string
    field :archived_at, nil, :utc_datetime_usec
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
