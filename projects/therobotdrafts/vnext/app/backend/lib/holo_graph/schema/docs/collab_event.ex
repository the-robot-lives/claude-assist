defmodule HoloGraph.Schema.Docs.CollabEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "collab_events" do
    belongs_to :graph_document, HoloGraph.Schema.Docs.GraphDocument, type: Ecto.UUID
    belongs_to :actor_user, HoloGraph.Schema.Users.User, type: Ecto.UUID

    field :version, :integer
    field :event_type, :string
    field :client_event_id, :string
    field :patch, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :graph_document_id,
      :actor_user_id,
      :version,
      :event_type,
      :client_event_id,
      :patch,
      :metadata
    ])
    |> validate_required([:graph_document_id, :event_type, :patch])
    |> validate_number(:version, greater_than: 0)
  end
end
