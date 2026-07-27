defmodule Timely.Schema.Sync.WorkspaceRevision do
  @moduledoc """
  The per-workspace revision counter. One row per workspace; see
  `Timely.Sync.Revisions` for why it is a table row and not a Postgres sequence.
  """
  use Ecto.Schema

  @primary_key {:workspace_id, Ecto.UUID, autogenerate: false}
  schema "timely_workspace_revisions" do
    field(:current_revision, :integer, default: 0)
    field(:tombstone_horizon_revision, :integer, default: 0)
    field(:horizon_pruned_at, :utc_datetime_usec)
    field(:created_at, :utc_datetime_usec)
    field(:updated_at, :utc_datetime_usec)
  end
end
