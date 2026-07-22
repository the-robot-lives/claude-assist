defmodule HoloGraph.Schema.Docs.GraphDocument do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "graph_documents" do
    belongs_to :organization, HoloGraph.Schema.Organizations.Organization, type: Ecto.UUID
    belongs_to :project, HoloGraph.Schema.Projects.Project, type: Ecto.UUID

    field :slug, :string
    field :title, :string
    field :summary, :string
    field :status, :string, default: "draft"
    field :current_version, :integer, default: 1
    field :document, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :organization_id,
      :project_id,
      :slug,
      :title,
      :summary,
      :status,
      :current_version,
      :document,
      :metadata
    ])
    |> validate_required([:slug, :title, :current_version, :document])
    |> validate_number(:current_version, greater_than: 0)
    |> validate_inclusion(:status, ["draft", "active", "archived", "deleted"])
    |> unique_constraint(:slug)
  end
end
