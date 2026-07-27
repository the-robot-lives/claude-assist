defmodule Timely.Schema.Sync.AppliedMutation do
  @moduledoc """
  The idempotency ledger (SYNC-PROTOCOL 9.1).

  `result` holds the verbatim `MutationResult` so a replay can be answered from
  the log without re-deriving anything. That matters: the protocol requires the
  **original** result, and re-running the conflict rules against a row that has
  since moved on would produce a different, wrong answer.

  `mutation_id` is the primary key because it is a client-generated UUIDv7 and
  globally unique. The `(workspace_id, mutation_id)` unique index the protocol
  asks for is kept as well, because that is the constraint whose violation
  answers two concurrent deliveries of the same batch.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:mutation_id, Ecto.UUID, autogenerate: false}
  schema "applied_mutations" do
    field(:workspace_id, Ecto.UUID)
    field(:device_id, Ecto.UUID)
    field(:status, :string)
    field(:reason, :string)
    field(:entity_kind, :string)
    field(:entity_id, Ecto.UUID)
    field(:resulting_server_revision, :integer)
    field(:result, :map, default: %{})
    field(:applied_at, :utc_datetime_usec)
  end

  @castable [
    :mutation_id,
    :workspace_id,
    :device_id,
    :status,
    :reason,
    :entity_kind,
    :entity_id,
    :resulting_server_revision,
    :result,
    :applied_at
  ]

  # ⟦𓅓𓏏𓎼𓋴⟧ changeset :: AppliedMutation ledger changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable)
    |> validate_required([:mutation_id, :workspace_id, :status])
    |> validate_inclusion(:status, Timely.Sync.Vocabulary.mutation_statuses())
    |> unique_constraint(:mutation_id, name: :applied_mutations_pkey)
    |> unique_constraint(:mutation_id, name: :uq_applied_mutations_workspace_mutation)
  end
end
