defmodule Timely.Sync.Blobs do
  @moduledoc """
  Screenshot image bytes: the one resource in Timely that does **not** sync by
  default (SYNC-PROTOCOL 10).

  A client that never uploads a byte is fully functional, and
  `GET .../blob` answering `404 blob_not_available` is the **normal** path, not
  an error - every read surface is metadata-sufficient, so companions render
  `captured_at`, the owning span, the origin device name, and the vision
  analysis's `status_update` / `evidence` instead.

  Storage is behind an adapter so the double-gate logic can be tested for real
  without a network round trip. The gate, not the adapter, is the part that has
  to be right.
  """

  require Logger

  alias Timely.Repo
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Sync.Policy
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  import Ecto.Query

  @max_bytes 16 * 1024 * 1024

  @doc "The largest body the upload endpoint accepts."
  # ⟦𓅓𓐍𓃀𓋴⟧ max_bytes :: Largest accepted blob body.
  def max_bytes, do: @max_bytes

  @doc """
  Stores image bytes for a screenshot, if and only if both gates are open.

  Returns `{:error, :forbidden, gates}` when either gate is closed. The rejected
  body is never buffered, quarantined or retained - the caller passes it in and
  it is dropped on the floor, which is the only implementation of "the server
  does not retain a rejected body" that is actually true.
  """
  # ⟦𓅱𓊪𓃀𓋴⟧ upload :: Stores screenshot bytes behind the double gate.
  def upload(workspace_id, screenshot_id, device_id, body, opts \\ []) do
    # The id comes from a path segment, so it is cast before it reaches a query:
    # `where id == ^value` on a non-uuid raises rather than returning nothing.
    screenshot =
      case Ecto.UUID.cast(screenshot_id) do
        {:ok, id} -> Workspace.fetch_live(Screenshot, workspace_id, id)
        :error -> nil
      end

    device = Policy.device(workspace_id, device_id)

    cond do
      # "the server will not create a metadata row from a blob" - the metadata
      # must already have arrived through /sync/mutations.
      is_nil(screenshot) ->
        {:error, :not_found}

      true ->
        case Policy.blob_gate(workspace_id, device) do
          {:error, gates} ->
            {:error, :forbidden, gates}

          {:ok, _gates} ->
            store(workspace_id, screenshot, device, body, opts)
        end
    end
  end

  defp store(workspace_id, screenshot, device, body, opts) do
    byte_size = byte_size(body)
    hash = :sha256 |> :crypto.hash(body) |> Base.encode16(case: :lower)

    with :ok <- verify_hash(hash, Keyword.get(opts, :expected_hash)),
         :ok <- verify_size(byte_size) do
      key = storage_key(workspace_id, screenshot.id)

      case adapter().put(key, body, Keyword.get(opts, :content_type, "image/png")) do
        :ok ->
          now = DateTime.utc_now()

          {:ok, updated} =
            Repo.transaction(fn ->
              revision = Revisions.allocate!(workspace_id)

              {1, [row]} =
                Screenshot
                |> Workspace.scope(workspace_id)
                |> where([s], s.id == ^screenshot.id)
                |> select([s], s)
                |> Repo.update_all(
                  set: [
                    upload_state: "uploaded",
                    blob_storage_key: key,
                    blob_content_hash: hash,
                    blob_byte_size: byte_size,
                    blob_uploaded_at: now,
                    updated_at: now,
                    updated_at_effective: now,
                    # Bumped so the metadata change reaches other devices
                    # through the ordinary pull loop.
                    server_revision: revision,
                    origin_device_id: (device && device.id) || screenshot.origin_device_id
                  ]
                )

              row
            end)

          {:ok, updated}

        {:error, reason} ->
          {:error, {:storage, reason}}
      end
    end
  end

  @doc """
  Reads the bytes back. `{:error, :not_available}` covers every screenshot whose
  `upload_state` is not `uploaded` - which is most of them - and clients MUST
  treat it as unremarkable.
  """
  # ⟦𓂧𓅱𓈖𓋴⟧ download :: Reads stored screenshot bytes.
  def download(workspace_id, screenshot_id) do
    case fetch_screenshot(workspace_id, screenshot_id) do
      %Screenshot{upload_state: "uploaded", blob_storage_key: key} = screenshot
      when is_binary(key) ->
        case adapter().get(key) do
          {:ok, body} -> {:ok, body, screenshot}
          {:error, _reason} -> {:error, :not_available}
        end

      _ ->
        {:error, :not_available}
    end
  end

  @doc """
  Deletes stored bytes for a screenshot. Used by the censorship cascade (row 16)
  and by the policy-revocation sweep.

  Failure to delete is logged rather than raised: the tombstone and the
  `purged` state are the parts that must land, and a storage backend that is
  briefly unavailable must not roll back a censorship assertion.
  """
  # ⟦𓊪𓅱𓂋𓎼⟧ purge :: Deletes stored bytes for a screenshot.
  def purge(%Screenshot{blob_storage_key: nil}), do: :ok

  def purge(%Screenshot{blob_storage_key: key}) do
    case adapter().delete(key) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("timely: failed to purge screenshot blob #{key}: #{inspect(reason)}")
        :ok
    end
  end

  @doc """
  Moves every stored blob in a workspace to `purge_pending` and then `purged`.
  Called when `screenshot_upload_allowed` flips back to false: metadata rows
  survive, so the timeline does not develop holes.
  """
  # ⟦𓋴𓅱𓂋𓊪⟧ revoke_workspace_blobs :: Purges all stored blobs in a workspace.
  def revoke_workspace_blobs(workspace_id) do
    Screenshot
    |> Workspace.scope(workspace_id)
    |> where([s], s.upload_state in ["uploaded", "pending", "eligible"])
    |> Repo.all()
    |> Enum.map(fn screenshot ->
      purge(screenshot)

      Repo.transaction(fn ->
        revision = Revisions.allocate!(workspace_id)
        now = DateTime.utc_now()

        Screenshot
        |> Workspace.scope(workspace_id)
        |> where([s], s.id == ^screenshot.id)
        |> Repo.update_all(
          set: [
            upload_state: "purged",
            blob_storage_key: nil,
            blob_content_hash: nil,
            blob_byte_size: nil,
            blob_uploaded_at: nil,
            updated_at: now,
            updated_at_effective: now,
            server_revision: revision
          ]
        )
      end)

      screenshot.id
    end)
  end

  defp fetch_screenshot(workspace_id, screenshot_id) do
    case Ecto.UUID.cast(screenshot_id) do
      {:ok, id} -> Workspace.fetch_live(Screenshot, workspace_id, id)
      :error -> nil
    end
  end

  defp storage_key(workspace_id, screenshot_id),
    do: "timely/#{workspace_id}/screenshots/#{screenshot_id}"

  defp verify_hash(_actual, nil), do: :ok
  defp verify_hash(actual, expected) when actual == expected, do: :ok
  defp verify_hash(_actual, _expected), do: {:error, :hash_mismatch}

  defp verify_size(size) when size > @max_bytes, do: {:error, :too_large}
  defp verify_size(0), do: {:error, :empty_body}
  defp verify_size(_size), do: :ok

  defp adapter do
    Application.get_env(:timely, __MODULE__, [])
    |> Keyword.get(:adapter, Timely.Sync.Blobs.S3)
  end
end
