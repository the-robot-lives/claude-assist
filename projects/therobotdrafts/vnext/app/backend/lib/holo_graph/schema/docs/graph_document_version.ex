defmodule HoloGraph.Schema.Docs.GraphDocumentVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "graph_document_versions" do
    belongs_to :graph_document, HoloGraph.Schema.Docs.GraphDocument, type: Ecto.UUID
    belongs_to :actor_user, HoloGraph.Schema.Users.User, type: Ecto.UUID

    field :version, :integer
    field :document, :map, default: %{}
    field :patch, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:graph_document_id, :actor_user_id, :version, :document, :patch, :metadata])
    |> validate_required([:graph_document_id, :version, :document])
    |> validate_number(:version, greater_than: 0)
    |> unique_constraint([:graph_document_id, :version])
  end
end
