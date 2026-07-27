defmodule Timely.Schema.Taxonomy.Ticket do
  @moduledoc """
  A name-keyed ticket, unique on `(workspace_id, project_id, canonical_name)`
  with a null `project_id` treated as its own scope.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "timely_tickets" do
    field(:name, :string)
    field(:canonical_name, :string)
    field(:client_id, Ecto.UUID)
    field(:project_id, Ecto.UUID)
    field(:client_name, :string, default: "")
    field(:project_name, :string, default: "")
    field(:notes, :string, default: "")
    field(:auto_created, :boolean, default: false)
    field(:merged_into_id, Ecto.UUID)
    field(:review_state, :string, default: "unreviewed")

    use Timely.Schema.Sync.Envelope
  end

  @castable [
    :id,
    :name,
    :canonical_name,
    :client_id,
    :project_id,
    :client_name,
    :project_name,
    :notes,
    :auto_created,
    :merged_into_id,
    :review_state
  ]

  # ⟦𓏏𓎡𓋴𓆓⟧ changeset :: Ticket changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :name, :canonical_name, :server_revision])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_inclusion(:review_state, Timely.Sync.Vocabulary.review_states())
    |> unique_constraint(:canonical_name, name: :uq_timely_tickets_canonical_scoped)
    |> unique_constraint(:canonical_name, name: :uq_timely_tickets_canonical_unscoped)
  end
end
