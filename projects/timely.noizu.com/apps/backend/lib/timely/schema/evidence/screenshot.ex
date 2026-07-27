defmodule Timely.Schema.Evidence.Screenshot do
  @moduledoc """
  Screenshot **metadata**, which always syncs. The image bytes are a separate,
  double-gated resource that defaults to never leaving the device
  (SYNC-PROTOCOL 10.1).

  Everything from `upload_state` down is server-owned: conflict matrix row 17
  says a client that tries to set `upload_state` or any `blob_*` field has those
  fields ignored rather than rejected, so they are absent from `@castable` and
  can only be written through `Timely.Sync.Blobs`.

  `file_name` is advisory provenance only and is **not** unique - the macOS
  agent formats it at second resolution, so two captures in one second collide.
  Nothing may key on it.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "screenshots" do
    field(:span_id, Ecto.UUID)
    field(:captured_at, :utc_datetime_usec)
    field(:file_name, :string, default: "")
    field(:active_app_name, :string, default: "")
    field(:upload_state, :string, default: "local_only")
    field(:blob_storage_key, :string)
    field(:blob_content_hash, :string)
    field(:blob_byte_size, :integer)
    field(:blob_uploaded_at, :utc_datetime_usec)
    field(:censored, :boolean, default: false)

    use Timely.Schema.Sync.Envelope
  end

  # Deliberately excludes upload_state and every blob_* field: those are server
  # owned and silently ignored on the client-facing path (conflict matrix 17).
  @castable [:id, :span_id, :captured_at, :file_name, :active_app_name]

  # Server-side writes go through here instead, so the ignore rule lives in one
  # place rather than being re-decided at each call site.
  @server_owned [
    :upload_state,
    :blob_storage_key,
    :blob_content_hash,
    :blob_byte_size,
    :blob_uploaded_at,
    :censored
  ]

  @doc "Client-originated changeset. Server-owned fields in `attrs` are ignored."
  # ⟦𓋴𓎡𓂋𓋴⟧ changeset :: Screenshot changeset from a client mutation.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :captured_at, :server_revision])
    |> validate_inclusion(:upload_state, Timely.Sync.Vocabulary.upload_states())
  end

  @doc "Server-side changeset for the fields the client may not touch."
  # ⟦𓋴𓂋𓆑𓋴⟧ server_changeset :: Screenshot changeset for server-owned blob state.
  def server_changeset(record, attrs) do
    record
    |> cast(attrs, @server_owned ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_inclusion(:upload_state, Timely.Sync.Vocabulary.upload_states())
    |> validate_number(:blob_byte_size, greater_than_or_equal_to: 0)
    |> validate_format(:blob_content_hash, ~r/^[0-9a-f]{64}$/)
  end
end
