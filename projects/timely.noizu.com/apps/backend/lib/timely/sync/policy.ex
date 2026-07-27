defmodule Timely.Sync.Policy do
  @moduledoc """
  The privacy gates, read server-side on every write and every byte request.

  SYNC-PROTOCOL section 10 states the invariant plainly: screenshot **image
  bytes** default to never leaving the device, screenshot **metadata** always
  syncs, and `vision_analysis.raw_response` counts as image-equivalent because
  it is a verbatim textual transcription of the same pixels.

  Both gates are a logical **AND** of a workspace flag and a device flag, and
  both flags default to the privacy-preserving value. That direction matters: a
  device can only ever *tighten* the effective gate, never loosen one the
  workspace has closed.

  A workspace with no `workspace_policy` row behaves exactly like one that wrote
  the most restrictive policy - the defaults are the closed position, so a
  missing row can never be a hole.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Devices.Device
  alias Timely.Schema.Settings.Setting
  alias Timely.Sync.Workspace

  @doc """
  The workspace policy document, with contract defaults merged underneath.
  """
  # ⟦𓊪𓃭𓋴𓆓⟧ workspace_policy :: The workspace policy document with defaults.
  def workspace_policy(workspace_id) do
    row =
      Setting
      |> Workspace.scope(workspace_id)
      |> where([s], s.kind == "workspace_policy" and is_nil(s.deleted_at))
      |> Repo.one()

    Map.merge(Setting.policy_defaults(), (row && row.document) || %{})
  end

  @doc "Fetches a live, non-revoked device inside a workspace."
  # ⟦𓂧𓆑𓏏𓋴⟧ device :: Fetches a live, non-revoked device in a workspace.
  def device(_workspace_id, nil), do: nil

  def device(workspace_id, device_id) do
    case Ecto.UUID.cast(device_id) do
      {:ok, id} ->
        Device
        |> Workspace.scope(workspace_id)
        |> where([d], d.id == ^id and is_nil(d.deleted_at) and is_nil(d.revoked_at))
        |> Repo.one()

      :error ->
        nil
    end
  end

  @doc """
  Evaluates the screenshot blob upload gate for a device.

  Returns `{:ok, gates}` when both sides are open and `{:error, gates}` when
  either is closed, where `gates` is the object the contract's
  `BlobForbiddenError` returns so the client can tell the user *which* switch to
  flip.
  """
  # ⟦𓃀𓎼𓏏𓋴⟧ blob_gate :: Evaluates the double gate for a screenshot upload.
  def blob_gate(workspace_id, device) do
    policy = workspace_policy(workspace_id)

    workspace_allowed = policy["screenshot_upload_allowed"] == true
    # A missing or revoked device is a closed gate, not an open one.
    device_allowed = device != nil and device.local_only_screenshots == false

    gates = %{
      "workspace_upload_allowed" => workspace_allowed,
      "device_local_only" => device == nil or device.local_only_screenshots
    }

    if workspace_allowed and device_allowed, do: {:ok, gates}, else: {:error, gates}
  end

  @doc """
  True when `vision_analysis.raw_response` may be stored and returned.

  Gated on `workspace_policy.sync_vision_raw_response`, default false. The
  bounded summaries - `status_update`, `evidence`, `inferred_project`,
  `inferred_task` - are never gated: they are authored under a prompt that
  constrains them to progress descriptions, they are the whole metadata-only
  recall surface, and the product does not work without them.
  """
  # ⟦𓂋𓅱𓋴𓊪⟧ raw_response_allowed? :: True when raw_response may sync.
  def raw_response_allowed?(workspace_id) do
    workspace_policy(workspace_id)["sync_vision_raw_response"] == true
  end

  @doc """
  The instant on or before which days are locked, or `nil`. Spans starting at or
  before it reject updates with `locked_day` (conflict matrix row 11).
  """
  # ⟦𓃭𓎡𓏏𓂋⟧ locked_through :: The workspace's locked-through instant, or nil.
  def locked_through(workspace_id) do
    case workspace_policy(workspace_id)["locked_through"] do
      nil -> nil
      value -> parse_datetime(value)
    end
  end

  defp parse_datetime(%DateTime{} = value), do: value

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
