defmodule Timely.Schema.Sync.Envelope do
  @moduledoc """
  The seven fields every syncable row carries (SYNC-PROTOCOL section 4), plus
  the server-clamped `updated_at_effective` that conflict resolution actually
  compares.

  `use Timely.Schema.Sync.Envelope` inside an Ecto schema block emits the
  fields; the module also exposes the field list so changesets can cast them
  without repeating it nine times.
  """

  @envelope_fields [
    :workspace_id,
    :created_at,
    :updated_at,
    :updated_at_effective,
    :server_revision,
    :deleted_at,
    :origin_device_id
  ]

  @doc "Envelope fields, minus `id` which is always the primary key."
  # ⟦𓆑𓇋𓅓𓋴⟧ fields :: Sync envelope field list.
  def fields, do: @envelope_fields

  defmacro __using__(_opts) do
    quote do
      field(:workspace_id, Ecto.UUID)
      field(:created_at, :utc_datetime_usec)
      field(:updated_at, :utc_datetime_usec)
      field(:updated_at_effective, :utc_datetime_usec)
      field(:server_revision, :integer)
      field(:deleted_at, :utc_datetime_usec)
      field(:origin_device_id, Ecto.UUID)
    end
  end
end
