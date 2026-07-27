defmodule Timely.Schema.Taxonomy.Client do
  @moduledoc """
  A name-keyed client. Unique on `(workspace_id, canonical_name)`; its id is the
  deterministic UUIDv5 from `Timely.Sync.Canon.client_id/2` so that two offline
  devices vivifying the same name converge without a round trip.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "timely_clients" do
    field(:name, :string)
    field(:canonical_name, :string)
    field(:notes, :string, default: "")
    field(:auto_created, :boolean, default: false)
    field(:merged_into_id, Ecto.UUID)
    field(:review_state, :string, default: "unreviewed")

    use Timely.Schema.Sync.Envelope
  end

  @castable [:id, :name, :canonical_name, :notes, :auto_created, :merged_into_id, :review_state]

  # ⟦𓎡𓃭𓊃𓋴⟧ changeset :: Client changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :name, :canonical_name, :server_revision])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_inclusion(:review_state, Timely.Sync.Vocabulary.review_states())
    |> unique_constraint(:canonical_name, name: :uq_timely_clients_canonical)
  end
end
