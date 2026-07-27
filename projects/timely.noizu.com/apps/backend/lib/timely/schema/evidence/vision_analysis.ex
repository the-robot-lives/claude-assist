defmodule Timely.Schema.Evidence.VisionAnalysis do
  @moduledoc """
  A model's reading of one screenshot. **Append-only**: conflict matrix row 14
  rejects every `update` with `immutable_entity`, and re-analysis creates a new
  row rather than mutating this one.

  `raw_response` is the model's verbatim output describing the screen, which is
  image-equivalent (SYNC-PROTOCOL 10.3): if the bytes stay on device but a full
  textual transcription of those same pixels syncs freely, the privacy promise
  is hollow. It is therefore gated on
  `workspace_policy.sync_vision_raw_response`, and when withheld the column
  stays `NULL` with `raw_response_withheld` true - which is what distinguishes
  "policy suppressed this" from "the source never had it".

  `status_update`, `evidence`, `inferred_project` and `inferred_task` always
  sync. They are the metadata-only recall surface a byte-free companion renders,
  and the product does not work without them.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "vision_analyses" do
    field(:screenshot_id, Ecto.UUID)
    field(:analyzed_at, :utc_datetime_usec)
    field(:model, :string, default: "")
    field(:status_update, :string, default: "")
    field(:inferred_project, :string, default: "")
    field(:inferred_task, :string, default: "")
    field(:project_switch_detected, :boolean, default: false)
    field(:confidence, :float, default: 0.0)
    field(:evidence, :string, default: "")
    field(:privacy_sensitive, :boolean, default: false)
    field(:privacy_category, :string, default: "none")
    field(:raw_response, :string)
    field(:raw_response_withheld, :boolean, default: true)
    field(:error_message, :string)

    use Timely.Schema.Sync.Envelope
  end

  # `raw_response` and `raw_response_withheld` are absent: the gate decides them,
  # not the payload. See `Timely.Sync.Privacy.apply_raw_response_gate/3`.
  @castable [
    :id,
    :screenshot_id,
    :analyzed_at,
    :model,
    :status_update,
    :inferred_project,
    :inferred_task,
    :project_switch_detected,
    :confidence,
    :evidence,
    :privacy_sensitive,
    :privacy_category,
    :error_message
  ]

  # ⟦𓆓𓋴𓈖𓋴⟧ changeset :: VisionAnalysis changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ [:raw_response, :raw_response_withheld])
    |> cast(attrs, Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :screenshot_id, :analyzed_at, :server_revision])
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_inclusion(:privacy_category, Timely.Sync.Vocabulary.privacy_categories())
  end

  @doc "Field list a client mutation may set; `raw_response` is not among them."
  # ⟦𓎡𓋴𓏏𓃀⟧ castable :: Client-settable field list.
  def castable, do: @castable
end
