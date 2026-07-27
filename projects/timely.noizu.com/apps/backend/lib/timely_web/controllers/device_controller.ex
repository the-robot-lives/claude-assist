defmodule TimelyWeb.DeviceController do
  @moduledoc """
  `POST /api/v1/devices` and `PATCH /api/v1/devices/{device_id}`.

  Registration is idempotent by client-supplied `device_id`, and `PATCH` exists
  chiefly because `local_only_screenshots` is half of the screenshot upload gate
  and has to be togglable from the device that actually holds the bytes.
  """
  use TimelyWeb, :controller

  import Ecto.Query
  import TimelyWeb.TimelyAuth

  alias Timely.Schema.Devices.Device
  alias Timely.Sync.Devices

  # ⟦𓂋𓎼𓋴𓈖⟧ create :: Registers or re-registers a device.
  def create(conn, params) do
    with_workspace(conn, params["workspace_id"], fn {conn, ctx} ->
      case Devices.register(ctx.workspace_id, ctx.user_id, params) do
        {:ok, device} ->
          json(conn, Devices.envelope(ctx.workspace_id, device))

        {:error, :invalid_device_id} ->
          error(conn, 400, "validation_failed", "device_id must be a uuid")

        {:error, :not_device_owner} ->
          error(conn, 403, "not_device_owner", "this device id belongs to another user")

        {:error, %Ecto.Changeset{} = changeset} ->
          error(conn, 400, "validation_failed", changeset_message(changeset))

        {:error, _reason} ->
          error(conn, 400, "validation_failed", "device could not be registered")
      end
    end)
  end

  # ⟦𓅱𓊪𓂧𓈖⟧ update :: Updates the caller's own device row.
  def update(conn, %{"device_id" => device_id} = params) do
    case workspace_id(params) do
      nil ->
        # `DeviceUpdate` carries no workspace_id and the path has only the
        # device id, so the workspace is inferred from the row. No row anywhere
        # means no such device - which the contract answers 404, not 400.
        error(conn, 404, "not_found", "no such device")

      workspace_id ->
        do_update(conn, workspace_id, device_id, params)
    end
  end

  defp do_update(conn, workspace_id, device_id, params) do
    with_workspace(conn, workspace_id, fn {conn, ctx} ->
      case Devices.update(ctx.workspace_id, ctx.user_id, device_id, params) do
        {:ok, device} ->
          json(conn, Devices.envelope(ctx.workspace_id, device))

        {:error, :not_found} ->
          error(conn, 404, "not_found", "no such device in this workspace")

        {:error, :not_device_owner} ->
          error(conn, 403, "not_device_owner", "only the owning device may be updated")

        {:error, %Ecto.Changeset{} = changeset} ->
          error(conn, 400, "validation_failed", changeset_message(changeset))

        {:error, _reason} ->
          error(conn, 400, "validation_failed", "device could not be updated")
      end
    end)
  end

  # `DeviceUpdate` has no `workspace_id` of its own, so it is taken from the
  # query string when present and otherwise inferred from the device row the
  # caller already owns.
  defp workspace_id(params) do
    params["workspace_id"] || device_workspace(params["device_id"])
  end

  defp device_workspace(device_id) do
    case Ecto.UUID.cast(device_id) do
      {:ok, id} ->
        Timely.Repo.one(from(d in Device, where: d.id == ^id, select: d.workspace_id))

      :error ->
        nil
    end
  end

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
  end
end
