defmodule Timely.Schema.Devices.Device do
  @moduledoc """
  One row per client install.

  `local_only_screenshots` is half of the screenshot upload gate
  (SYNC-PROTOCOL 10.1) and defaults to the privacy-preserving `true`. The
  effective gate is the logical AND of this flag and the workspace policy, so a
  device can only ever *tighten* it - registering with `false` does not open
  anything the workspace has not already opened.

  Only macOS captures (section 1). The `is_capture_agent` claim is refused
  outright for any other platform, both here and by a table `CHECK`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "devices" do
    field(:user_id, Ecto.UUID)
    field(:platform, :string)
    field(:name, :string, default: "")
    field(:app_version, :string, default: "")
    field(:os_version, :string)
    field(:local_only_screenshots, :boolean, default: true)
    field(:is_capture_agent, :boolean, default: false)
    field(:last_seen_at, :utc_datetime_usec)
    field(:last_sync_revision, :integer, default: 0)
    field(:revoked_at, :utc_datetime_usec)

    use Timely.Schema.Sync.Envelope
  end

  @castable [
    :id,
    :user_id,
    :platform,
    :name,
    :app_version,
    :os_version,
    :local_only_screenshots,
    :is_capture_agent,
    :last_seen_at,
    :last_sync_revision,
    :revoked_at
  ]

  # ⟦𓂧𓋴𓎡𓋴⟧ changeset :: Device changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :user_id, :platform, :server_revision])
    |> validate_inclusion(:platform, Timely.Sync.Vocabulary.device_platforms())
    |> validate_length(:name, max: 200)
    |> validate_capture_agent()
  end

  # A companion that claims capture is not a policy question the server can
  # answer later - it is a lie about what the install is, so it fails validation
  # rather than being silently downgraded.
  defp validate_capture_agent(changeset) do
    if get_field(changeset, :is_capture_agent) && get_field(changeset, :platform) != "macos" do
      add_error(changeset, :is_capture_agent, "only a macos device may be a capture agent")
    else
      changeset
    end
  end
end
