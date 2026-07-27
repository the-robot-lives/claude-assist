defmodule Timely.Sync.Devices do
  @moduledoc """
  Device registration and the `DeviceEnvelope` a client bootstraps from.

  Registration is **idempotent by client-supplied `device_id`** so that a device
  which reinstalls and reuses its persisted id keeps its `origin_device_id`
  history - and with it every LWW tie-break that history participates in.

  `local_only_screenshots` is half of the screenshot upload gate and defaults to
  `true`. A device registering with `false` does not open anything: the
  effective gate is the AND of this flag and the workspace policy, so a device
  can only ever tighten it.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Devices.Device
  alias Timely.Sync.Entities
  alias Timely.Sync.Policy
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  @doc """
  Registers or re-registers a device. Returns `{:ok, device}`.
  """
  # ⟦𓂋𓎼𓋴𓏏⟧ register :: Registers or re-registers a device.
  def register(workspace_id, user_id, params) do
    device_id = params["device_id"]
    now = DateTime.utc_now()

    # Validated before it is used in a query: `where id == ^device_id` on a
    # non-uuid raises Ecto.Query.CastError, which would surface as a 500 instead
    # of the 400 the contract specifies.
    existing =
      if valid_uuid?(device_id),
        do: Workspace.fetch_any(Device, workspace_id, device_id),
        else: nil

    cond do
      not valid_uuid?(device_id) ->
        {:error, :invalid_device_id}

      # A device id already claimed by a different user in this workspace is not
      # a re-registration, it is a collision. Adopting it would let one person's
      # captured workday be attributed to another's device row.
      existing != nil and existing.user_id != user_id ->
        {:error, :not_device_owner}

      true ->
        Repo.transaction(fn ->
          revision = Revisions.allocate!(workspace_id)

          attrs = %{
            "id" => device_id,
            "workspace_id" => workspace_id,
            "user_id" => user_id,
            "platform" => params["platform"],
            "name" => params["name"] || "",
            "app_version" => params["app_version"] || "",
            "os_version" => params["os_version"],
            "local_only_screenshots" => default_local_only(workspace_id, params, existing),
            "is_capture_agent" => params["is_capture_agent"] || false,
            "last_seen_at" => now,
            "last_sync_revision" => (existing && existing.last_sync_revision) || 0,
            # Re-registering un-revokes: the user has just proved they hold the
            # device and can sign in on it.
            "revoked_at" => nil,
            "created_at" => (existing && existing.created_at) || now,
            "updated_at" => now,
            "updated_at_effective" => now,
            "server_revision" => revision,
            "deleted_at" => nil,
            "origin_device_id" => device_id
          }

          case (existing || %Device{}) |> Device.changeset(attrs) |> Repo.insert_or_update() do
            {:ok, device} -> device
            {:error, changeset} -> Repo.rollback({:invalid, changeset})
          end
        end)
        |> case do
          {:ok, device} -> {:ok, device}
          {:error, {:invalid, changeset}} -> {:error, changeset}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  # A device that says nothing inherits the workspace default, which is itself
  # the privacy-preserving value unless an admin has deliberately changed it.
  defp default_local_only(workspace_id, params, existing) do
    cond do
      is_boolean(params["local_only_screenshots"]) -> params["local_only_screenshots"]
      existing != nil -> existing.local_only_screenshots
      true -> Policy.workspace_policy(workspace_id)["default_local_only_screenshots"] != false
    end
  end

  @doc """
  Updates a device's name, version, or privacy flag.

  `{:error, :not_device_owner}` when the row belongs to someone else - which is
  also the answer for a device in another workspace, because `fetch_any/3` is
  workspace-scoped and simply does not find it.
  """
  # ⟦𓅱𓊪𓂧𓋴⟧ update :: Updates a device's own row.
  def update(workspace_id, user_id, device_id, params) do
    # Same reason as `register/3`: the id arrives from a path segment and must
    # be a uuid before it reaches a query.
    case valid_uuid?(device_id) && Workspace.fetch_any(Device, workspace_id, device_id) do
      falsy when falsy in [nil, false] ->
        {:error, :not_found}

      %Device{user_id: owner} when owner != user_id ->
        {:error, :not_device_owner}

      device ->
        now = DateTime.utc_now()

        Repo.transaction(fn ->
          revision = Revisions.allocate!(workspace_id)

          attrs =
            %{
              "updated_at" => now,
              "updated_at_effective" => now,
              "server_revision" => revision,
              "last_seen_at" => now
            }
            |> put_if(params, "name")
            |> put_if(params, "app_version")
            |> put_if(params, "os_version")
            |> put_if(params, "local_only_screenshots")

          case device |> Device.changeset(attrs) |> Repo.update() do
            {:ok, updated} -> updated
            {:error, changeset} -> Repo.rollback({:invalid, changeset})
          end
        end)
        |> case do
          {:ok, updated} -> {:ok, updated}
          {:error, {:invalid, changeset}} -> {:error, changeset}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  The `DeviceEnvelope` a client bootstraps from: its own row, the workspace
  policy it must obey, the server clock, and the cursor to start pulling from.
  """
  # ⟦𓆑𓈖𓅱𓋴⟧ envelope :: Builds the DeviceEnvelope bootstrap payload.
  def envelope(workspace_id, device) do
    policy_row =
      Timely.Schema.Settings.Setting
      |> Workspace.scope(workspace_id)
      |> where([s], s.kind == "workspace_policy" and is_nil(s.deleted_at))
      |> Repo.one()

    %{
      "device" => Entities.wire(device),
      "workspace_policy" => workspace_policy_wire(workspace_id, policy_row),
      "server_time" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "sync_cursor" => Revisions.committed_watermark(workspace_id)
    }
  end

  # A workspace that has never written a policy row still owes the client a
  # complete policy document; the defaults are the closed position, so a
  # synthesised one is safe.
  defp workspace_policy_wire(workspace_id, nil) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    Timely.Schema.Settings.Setting.policy_defaults()
    |> Map.merge(%{
      "id" => workspace_id,
      "workspace_id" => workspace_id,
      "kind" => "workspace_policy",
      "created_at" => now,
      "updated_at" => now,
      "server_revision" => 0,
      "deleted_at" => nil,
      "origin_device_id" => nil
    })
  end

  defp workspace_policy_wire(_workspace_id, row), do: Entities.wire(row)

  defp put_if(attrs, params, key) do
    if Map.has_key?(params, key), do: Map.put(attrs, key, params[key]), else: attrs
  end

  defp valid_uuid?(value) when is_binary(value), do: match?({:ok, _}, Ecto.UUID.cast(value))
  defp valid_uuid?(_), do: false
end
