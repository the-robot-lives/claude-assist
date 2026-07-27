defmodule TimelyWeb.SyncController do
  @moduledoc """
  `GET /api/v1/sync/changes` and `POST /api/v1/sync/mutations` - the whole sync
  loop.

  Note what a `200` from `mutations` does and does not mean: the batch was
  processed, but each `MutationResult` carries its own status and any of them
  may be `conflict` or `rejected`. Only an `atomic: true` batch that could not be
  applied in full answers `409`.
  """
  use TimelyWeb, :controller

  import TimelyWeb.TimelyAuth

  alias Timely.Sync.Changes
  alias Timely.Sync.Mutations
  alias Timely.Sync.Revisions

  # ⟦𓊪𓅱𓃭𓈖⟧ changes :: Pulls a page of changes since a revision.
  def changes(conn, params) do
    with_workspace(conn, params["workspace_id"], fn {conn, ctx} ->
      opts = [
        since: params["since"] || 0,
        limit: params["limit"],
        entities: Changes.parse_entities(params["entities"]),
        blob_url_builder: ctx.blob_url_builder
      ]

      case Changes.pull(ctx.workspace_id, opts) do
        {:ok, page} ->
          json(conn, page)

        {:error, :cursor_too_old, horizon} ->
          error(
            conn,
            410,
            "cursor_too_old",
            "since predates the tombstone horizon; re-bootstrap from 0",
            %{"tombstone_horizon_revision" => horizon}
          )
      end
    end)
  end

  # ⟦𓅓𓅱𓏏𓋴⟧ mutations :: Applies a batch of pushed mutations.
  def mutations(conn, params) do
    with_workspace(conn, params["workspace_id"], fn {conn, ctx} ->
      mutations = params["mutations"]

      if not is_list(mutations) do
        error(conn, 400, "validation_failed", "mutations must be an array")
      else
        ctx =
          ctx
          |> Map.put(:atomic, params["atomic"] == true)
          # The batch's device is named in the body; the header form is only for
          # the blob endpoints.
          |> Map.put(:device_id, params["device_id"] || ctx.device_id)

        case Mutations.push(ctx, mutations) do
          {:ok, results} ->
            json(conn, response(results, ctx.workspace_id))

          {:conflict, results} ->
            conn
            |> put_status(409)
            |> json(response(results, ctx.workspace_id))

          {:error, :empty_batch} ->
            error(conn, 400, "validation_failed", "mutations must not be empty")

          {:error, :batch_too_large} ->
            error(
              conn,
              413,
              "payload_too_large",
              "at most 200 mutations per batch, or 50 when atomic"
            )
        end
      end
    end)
  end

  defp response(results, workspace_id) do
    %{
      "results" => results,
      # A hint only. The client MUST still pull, because the server produces
      # side effects on rows the pusher never touched - auto-vivified projects,
      # duplicate flags raised on *other* spans.
      "next_cursor" => Revisions.committed_watermark(workspace_id),
      "server_time" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
