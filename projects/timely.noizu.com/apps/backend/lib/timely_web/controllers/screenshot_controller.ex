defmodule TimelyWeb.ScreenshotController do
  @moduledoc """
  `POST` and `GET /api/v1/screenshots/{screenshot_id}/blob`.

  Uploading bytes is never required, and `404` from the download is the
  **normal** path rather than an error - clients render the metadata-only recall
  surface instead and must not surface it to the user as a failure.

  Neither route carries a `workspace_id` parameter, so the workspace is derived:
  from the uploading device on `POST`, and from the screenshot's own row on
  `GET`. Membership is then checked against that workspace, so a caller can only
  ever reach bytes in a workspace they belong to.
  """
  use TimelyWeb, :controller

  import Ecto.Query
  import TimelyWeb.TimelyAuth

  alias Timely.Repo
  alias Timely.Schema.Devices.Device
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Sync.Blobs
  alias Timely.Sync.Entities
  alias Timely.Sync.Workspace

  # ⟦𓅱𓊪𓃀𓈖⟧ upload :: Uploads screenshot bytes behind the double gate.
  def upload(conn, %{"screenshot_id" => screenshot_id}) do
    case device_from_header(conn) do
      nil ->
        error(conn, 400, "validation_failed", "X-Timely-Device-Id header is required")

      device ->
        with_workspace(conn, device.workspace_id, fn {conn, ctx} ->
          cond do
            device.user_id != ctx.user_id ->
              error(conn, 403, "not_device_owner", "that device belongs to another user")

            true ->
              {:ok, body, conn} = read_full_body(conn)

              opts = [
                expected_hash: header(conn, "x-timely-content-sha256"),
                content_type: header(conn, "content-type") || "image/png"
              ]

              do_upload(conn, ctx.workspace_id, screenshot_id, device.id, body, opts)
          end
        end)
    end
  end

  defp do_upload(conn, workspace_id, screenshot_id, device_id, body, opts) do
    case Blobs.upload(workspace_id, screenshot_id, device_id, body, opts) do
      {:ok, screenshot} ->
        conn
        |> put_status(201)
        |> json(%{
          "screenshot_id" => screenshot.id,
          "upload_state" => screenshot.upload_state,
          "blob_byte_size" => screenshot.blob_byte_size,
          "blob_content_hash" => screenshot.blob_content_hash,
          "blob_url" => "/api/v1/screenshots/#{screenshot.id}/blob",
          "blob_uploaded_at" => screenshot.blob_uploaded_at && DateTime.to_iso8601(screenshot.blob_uploaded_at),
          "server_revision" => screenshot.server_revision
        })

      {:error, :not_found} ->
        error(conn, 404, "not_found", "no screenshot metadata row with this id")

      # The rejected body is not buffered, quarantined or retained; the `gates`
      # object names which side is closed so the user can be told what to change.
      {:error, :forbidden, gates} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          409,
          Jason.encode!(%{
            "code" => "blob_upload_forbidden",
            "message" => "screenshot upload is not permitted by policy or device flag",
            "gates" => gates
          })
        )
        |> halt()

      {:error, :hash_mismatch} ->
        error(conn, 400, "validation_failed", "body does not match X-Timely-Content-Sha256")

      {:error, :too_large} ->
        error(conn, 413, "payload_too_large", "screenshot exceeds the workspace blob limit")

      {:error, :empty_body} ->
        error(conn, 400, "validation_failed", "empty body")

      {:error, {:storage, _reason}} ->
        error(conn, 400, "storage_failed", "the blob could not be stored")
    end
  end

  # ⟦𓂧𓅱𓈖𓃭⟧ download :: Streams previously uploaded screenshot bytes.
  def download(conn, %{"screenshot_id" => screenshot_id}) do
    case screenshot_workspace(screenshot_id) do
      nil ->
        error(conn, 404, "blob_not_available", "the bytes are not on the server")

      workspace_id ->
        with_workspace(conn, workspace_id, fn {conn, ctx} ->
          case Blobs.download(ctx.workspace_id, screenshot_id) do
            {:ok, body, _screenshot} ->
              conn
              |> put_resp_content_type("image/png")
              |> send_resp(200, body)

            {:error, :not_available} ->
              # The normal path for every local-only screenshot, which is most
              # of them. Clients must treat it as unremarkable.
              error(conn, 404, "blob_not_available", "the bytes are not on the server")
          end
        end)
    end
  end

  @doc """
  `GET /api/v1/screenshots/{screenshot_id}` - the metadata row on its own, which
  is the surface a byte-free client actually renders.
  """
  # ⟦𓋴𓎡𓅱𓈖⟧ show :: Returns screenshot metadata.
  def show(conn, %{"screenshot_id" => screenshot_id}) do
    case screenshot_workspace(screenshot_id) do
      nil ->
        error(conn, 404, "not_found", "no such screenshot")

      workspace_id ->
        with_workspace(conn, workspace_id, fn {conn, ctx} ->
          case Workspace.fetch_live(Screenshot, ctx.workspace_id, screenshot_id) do
            nil -> error(conn, 404, "not_found", "no such screenshot")
            row -> json(conn, Entities.wire(row, blob_url_builder: ctx.blob_url_builder))
          end
        end)
    end
  end

  # Looked up without a workspace filter on purpose - this *is* how the
  # workspace is discovered - and every caller immediately authorizes membership
  # of whatever comes back, so no row is ever read on the strength of this alone.
  defp screenshot_workspace(screenshot_id) do
    case Ecto.UUID.cast(screenshot_id) do
      {:ok, id} ->
        Repo.one(from(s in Screenshot, where: s.id == ^id, select: s.workspace_id))

      :error ->
        nil
    end
  end

  defp device_from_header(conn) do
    with [raw | _] <- get_req_header(conn, "x-timely-device-id"),
         {:ok, id} <- Ecto.UUID.cast(raw) do
      Repo.one(from(d in Device, where: d.id == ^id and is_nil(d.deleted_at)))
    else
      _ -> nil
    end
  end

  defp header(conn, name) do
    case get_req_header(conn, name) do
      [value | _] -> value
      [] -> nil
    end
  end

  defp read_full_body(conn, acc \\ []) do
    case read_body(conn, length: Blobs.max_bytes()) do
      {:ok, chunk, conn} -> {:ok, IO.iodata_to_binary([acc, chunk]), conn}
      {:more, chunk, conn} -> read_full_body(conn, [acc, chunk])
      {:error, _reason} -> {:ok, IO.iodata_to_binary(acc), conn}
    end
  end
end
