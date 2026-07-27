defmodule Timely.Schema.Evidence.CensoredScreenshot do
  @moduledoc """
  The record left behind when a capture is censored. **Append-only**: conflict
  matrix row 15 rejects every `update` with `immutable_entity`.

  Creating one of these is an *assertion of censorship*, not a plain insert. The
  macOS agent hard-deletes the PNG and drops the local rows outright, which a
  protocol that never hard-deletes cannot express as-is; the mapping is a
  cascade (row 16) run by `Timely.Sync.Mutations`: the referenced screenshot is
  tombstoned, its analyses are tombstoned, any stored blob is deleted and
  `upload_state` becomes `purged`.

  `deleted_local_file` is the origin device's report about **its own disk**. It
  says nothing about any other device and must not be rendered as a
  workspace-wide claim.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "censored_screenshots" do
    field(:screenshot_id, Ecto.UUID)
    field(:span_id, Ecto.UUID)
    field(:file_name, :string, default: "")
    field(:active_app_name, :string, default: "")
    field(:captured_at, :utc_datetime_usec)
    field(:censored_at, :utc_datetime_usec)
    field(:model, :string, default: "")
    field(:category, :string, default: "none")
    field(:reason, :string, default: "")
    field(:confidence, :float, default: 0.0)
    field(:deleted_local_file, :boolean, default: false)

    use Timely.Schema.Sync.Envelope
  end

  @castable [
    :id,
    :screenshot_id,
    :span_id,
    :file_name,
    :active_app_name,
    :captured_at,
    :censored_at,
    :model,
    :category,
    :reason,
    :confidence,
    :deleted_local_file
  ]

  # ⟦𓎡𓋴𓂋𓋴⟧ changeset :: CensoredScreenshot changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([
      :id,
      :workspace_id,
      :screenshot_id,
      :captured_at,
      :censored_at,
      :server_revision
    ])
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_inclusion(:category, Timely.Sync.Vocabulary.privacy_categories())
  end
end
