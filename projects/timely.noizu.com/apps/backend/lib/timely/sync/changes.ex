defmodule Timely.Sync.Changes do
  @moduledoc """
  The pull path: `GET /api/v1/sync/changes?since=<rev>`.

  The cursor is a **revision, not a timestamp**, and section 5 of the protocol
  spends a page on why. The short version is that a timestamp cursor loses rows
  silently: a row whose timestamp is stamped at statement time but whose
  transaction commits later can be skipped by a puller that has already read
  past that timestamp, and the loss does not announce itself. Client clock skew,
  same-millisecond ties, and non-monotonic time (NTP steps, DST, VM suspend,
  laptop sleep) each break it independently.

  Two obligations follow, and both are honoured here:

  - `next_cursor` never advances past the highest **gap-free committed**
    revision. `Timely.Sync.Revisions.committed_watermark/1` is that ceiling, and
    every bucket query is capped by it, so a transaction that commits "behind"
    the watermark is impossible rather than merely unlikely.
  - Tombstones are included. A client must apply them even for rows it has never
    seen, where applying is a no-op.

  `limit` caps rows **across all buckets combined**, so the page is merged and
  truncated by revision rather than per bucket - otherwise a workspace with a
  busy bucket could starve a quiet one forever.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Sync.Entities
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  @default_limit 500
  @max_limit 2000

  @doc """
  Returns one page of changes.

  `{:error, :cursor_too_old}` when `since` has fallen below the tombstone
  horizon: the client has to discard its mirror and re-bootstrap from 0. Its
  unpushed local mutations survive that - the push queue is separate from the
  mirror.
  """
  # ⟦𓊪𓅱𓃭𓋴⟧ pull :: Returns one page of changes since a revision.
  def pull(workspace_id, opts \\ []) do
    since = opts |> Keyword.get(:since, 0) |> normalize_since()
    limit = opts |> Keyword.get(:limit) |> normalize_limit()
    only = Keyword.get(opts, :entities)
    horizon = Revisions.tombstone_horizon(workspace_id)

    # `since = 0` is an explicit bootstrap and is always honoured; it is the
    # answer to `410`, so it cannot also be a cause of one.
    if since > 0 and since < horizon do
      {:error, :cursor_too_old, horizon}
    else
      watermark = Revisions.committed_watermark(workspace_id)
      rows = collect(workspace_id, since, limit, watermark, only)

      page = Enum.take(rows, limit)
      has_more = length(rows) > limit

      next_cursor =
        case {has_more, List.last(page)} do
          # Truncated: resume from the last row actually delivered.
          {true, {revision, _bucket, _row}} -> revision
          # Complete: the client is caught up to the committed watermark, which
          # is what lets a quiet workspace stop polling from 0 forever.
          _ -> watermark
        end

      {:ok,
       %{
         "changes" => bucketize(page, opts),
         "next_cursor" => next_cursor,
         "has_more" => has_more,
         "tombstone_horizon_revision" => horizon,
         "server_time" => DateTime.utc_now() |> DateTime.to_iso8601()
       }}
    end
  end

  # Each bucket contributes at most `limit + 1` rows; the merge then decides
  # which of them fit. The extra row is what distinguishes "exactly full" from
  # "there is more".
  defp collect(workspace_id, since, limit, watermark, only) do
    Entities.buckets()
    |> Enum.filter(fn {bucket, _schema, _kind} -> only == nil or bucket in only end)
    |> Enum.flat_map(fn {bucket, schema, _kind} ->
      schema
      # The isolation boundary: a cross-workspace row is not filtered out later,
      # it is never selected.
      |> Workspace.scope(workspace_id)
      |> where([r], r.server_revision > ^since and r.server_revision <= ^watermark)
      |> order_by([r], asc: r.server_revision)
      |> limit(^(limit + 1))
      |> Repo.all()
      |> Enum.map(&{&1.server_revision, bucket, &1})
    end)
    |> Enum.sort_by(fn {revision, _bucket, _row} -> revision end)
  end

  defp bucketize(page, opts) do
    empty = Map.new(Entities.buckets(), fn {bucket, _schema, _kind} -> {bucket, []} end)

    page
    |> Enum.group_by(
      fn {_revision, bucket, _row} -> bucket end,
      fn {_revision, _bucket, row} -> Entities.wire(row, opts) end
    )
    |> then(&Map.merge(empty, &1))
  end

  defp normalize_since(value) when is_integer(value) and value >= 0, do: value

  defp normalize_since(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 0 -> parsed
      _ -> 0
    end
  end

  defp normalize_since(_), do: 0

  defp normalize_limit(nil), do: @default_limit
  defp normalize_limit(value) when is_integer(value), do: value |> max(1) |> min(@max_limit)

  defp normalize_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> normalize_limit(parsed)
      _ -> @default_limit
    end
  end

  defp normalize_limit(_), do: @default_limit

  @doc "Parses the optional `entities=` bucket filter into a list, or nil for all."
  # ⟦𓆑𓏏𓂋𓋴⟧ parse_entities :: Parses the entities bucket filter.
  def parse_entities(nil), do: nil
  def parse_entities(""), do: nil

  def parse_entities(value) when is_binary(value) do
    valid = Enum.map(Entities.buckets(), fn {bucket, _schema, _kind} -> bucket end)

    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 in valid))
    |> case do
      [] -> nil
      buckets -> buckets
    end
  end

  def parse_entities(_), do: nil
end
