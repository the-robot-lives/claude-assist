defmodule Timely.Schema.Settings.Setting do
  @moduledoc """
  The `settings` bucket, a discriminated union on `kind` so that user
  preferences and workspace policy share one revision stream (contract:
  `SettingsRow`).

  The body lives in `document` rather than in columns because conflict matrix
  row 20 resolves `user_settings` by LWW **on the whole document** - there are no
  per-field semantics to model, and modelling them in columns would invite a
  field-level merge the protocol does not yet define.

  Two singletons, both enforced by partial unique indexes:
  `workspace_policy` is one per workspace with `id == workspace_id`, and
  `user_settings` is one per `(workspace, user)` with the deterministic id from
  `Timely.Sync.Canon.user_settings_id/2`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "settings" do
    field(:kind, :string)
    field(:user_id, Ecto.UUID)
    field(:document, :map, default: %{})

    use Timely.Schema.Sync.Envelope
  end

  @castable [:id, :kind, :user_id, :document]

  # The contract's defaults. Both privacy gates default closed, so a workspace
  # that has never written a policy row behaves exactly like one that wrote the
  # most restrictive policy.
  @policy_defaults %{
    "kind" => "workspace_policy",
    "screenshot_upload_allowed" => false,
    "sync_vision_raw_response" => false,
    "default_local_only_screenshots" => true,
    "screenshot_retention_days" => 0,
    "blob_retention_days" => 30,
    "require_approval_before_export" => false,
    "idle_threshold_minutes" => 5,
    "locked_through" => nil
  }

  @user_defaults %{
    "kind" => "user_settings",
    "screenshot_interval_minutes" => 5,
    "screenshot_capture_enabled" => true,
    "pomodoro_work_minutes" => 25,
    "pomodoro_break_minutes" => 5,
    "local_only_screenshots" => true,
    "retention_days" => 0,
    "idle_threshold_minutes" => 5
  }

  # ⟦𓋴𓏏𓈖𓋴⟧ changeset :: Settings changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :kind, :server_revision])
    |> validate_inclusion(:kind, Timely.Sync.Vocabulary.settings_kinds())
    |> validate_kind_shape()
  end

  defp validate_kind_shape(changeset) do
    case {get_field(changeset, :kind), get_field(changeset, :user_id)} do
      {"user_settings", nil} -> add_error(changeset, :user_id, "is required for user_settings")
      {"workspace_policy", nil} -> changeset
      {"workspace_policy", _} -> add_error(changeset, :user_id, "must be null for workspace_policy")
      _ -> changeset
    end
  end

  @doc "The contract defaults for a workspace that has never written a policy row."
  # ⟦𓊪𓃭𓋴𓆓⟧ policy_defaults :: Default workspace_policy document.
  def policy_defaults, do: @policy_defaults

  @doc "The contract defaults for a user who has never written settings."
  # ⟦𓅱𓋴𓂧𓆑⟧ user_defaults :: Default user_settings document.
  def user_defaults, do: @user_defaults
end
