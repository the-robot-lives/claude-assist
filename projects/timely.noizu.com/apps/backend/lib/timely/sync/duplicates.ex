defmodule Timely.Sync.Duplicates do
  @moduledoc """
  Suspected-duplicate and billing-overlap detection (SYNC-PROTOCOL 8.3).

  What this module does: appends a `ReviewReason` to **both** rows of a
  suspicious pair with `raised_by: server` and `resolution: pending`, sets
  `review_state: needs_review`, and allocates a fresh `server_revision` on both
  so the flag reaches every device through the ordinary pull.

  What it deliberately does **not** do: merge, delete, adjust boundaries, pick a
  winner, or hide either row. "Review beats recall" - the user has context the
  server does not, and an auto-merge that guesses wrong destroys billable
  evidence. Only a client mutation setting `resolution` clears a flag.

  Two things are *not* conflicts and must not be flagged:

  - Overlapping spans as such (row 8). Parallel work is the product.
  - Overlapping billable spans resolving to the **same** client. That is the
    parallel-work case again, and the weighted rollup in `/reports/summary`
    already prevents the contested interval from being billed twice.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Canon
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  # Detection is bounded so a workspace with a pathological number of
  # same-titled spans in one window cannot make one push do unbounded work.
  @scan_window_seconds 24 * 60 * 60
  @max_pairs 20

  @duplicate_start_tolerance 120
  @duplicate_end_tolerance 120
  @billing_overlap_minimum 60

  @doc """
  Scans for suspicious pairs against one just-written span and raises flags on
  both sides of each pair.

  Returns the candidate row as it stands afterwards - which is not the row that
  was passed in, because raising a flag on it bumps its revision.
  """
  # ⟦𓂧𓅱𓊪𓋴⟧ scan :: Flags suspected duplicates and billing overlaps.
  def scan(workspace_id, %TimeSpan{} = candidate, ctx) do
    neighbours = neighbours(workspace_id, candidate)

    duplicates =
      neighbours
      |> Enum.filter(&suspected_duplicate?(candidate, &1))
      |> Enum.take(@max_pairs)
      |> Enum.map(&{"suspected_duplicate", &1})

    overlaps =
      neighbours
      |> Enum.filter(&billing_overlap?(candidate, &1, ctx.now))
      |> Enum.take(@max_pairs)
      |> Enum.map(&{"billing_overlap", &1})

    (duplicates ++ overlaps)
    |> Enum.reduce(candidate, fn {code, other}, current ->
      raise_pair(workspace_id, code, current, other, ctx)
    end)
  end

  @doc """
  Appends a review reason to a row unless an identical pending one is already
  there, and bumps its revision when something actually changed.

  Idempotence matters here: every update to a span re-runs detection, and
  without the dedupe a span edited ten times would accumulate ten identical
  `suspected_duplicate` flags pointing at the same neighbour.
  """
  # ⟦𓂋𓋴𓈖𓆑⟧ raise_flag :: Appends a review reason to a row, idempotently.
  def raise_flag(workspace_id, %TimeSpan{} = row, code, related_id, ctx, detail \\ nil) do
    existing = row.review_reasons || []

    already? =
      Enum.any?(existing, fn reason ->
        reason["code"] == code and reason["related_id"] == related_id and
          reason["resolution"] == "pending"
      end)

    if already? do
      row
    else
      reason = %{
        "code" => code,
        "detail" => detail,
        "related_id" => related_id,
        "raised_at" => DateTime.to_iso8601(ctx.now),
        "raised_by" => "server",
        "resolution" => "pending",
        "resolved_at" => nil
      }

      revision = Revisions.allocate!(workspace_id)

      {1, [updated]} =
        TimeSpan
        |> Workspace.scope(workspace_id)
        |> where([s], s.id == ^row.id)
        |> select([s], s)
        |> Repo.update_all(
          set: [
            review_reasons: existing ++ [reason],
            review_state: "needs_review",
            server_revision: revision,
            updated_at_effective: ctx.now
          ]
        )

      updated
    end
  end

  # The scan is limited to spans whose start is within 24 hours of the
  # candidate's, which is what makes this bounded rather than a full-table walk.
  defp neighbours(workspace_id, candidate) do
    window_start = DateTime.add(candidate.start_at, -@scan_window_seconds, :second)
    window_end = DateTime.add(candidate.start_at, @scan_window_seconds, :second)

    TimeSpan
    |> Workspace.scope(workspace_id)
    |> where([s], is_nil(s.deleted_at))
    |> where([s], s.id != ^candidate.id)
    |> where([s], s.start_at >= ^window_start and s.start_at <= ^window_end)
    |> limit(500)
    |> Repo.all()
  end

  defp suspected_duplicate?(a, b) do
    a.id != b.id and
      within?(a.start_at, b.start_at, @duplicate_start_tolerance) and
      ends_match?(a, b) and
      a.project_id == b.project_id and
      titles_match?(a, b)
  end

  # "both end null, or |end_a - end_b| <= 120s". One open and one closed is not
  # a match: an open span is still being written and has no comparable end.
  defp ends_match?(%{end_at: nil}, %{end_at: nil}), do: true
  defp ends_match?(%{end_at: nil}, _), do: false
  defp ends_match?(_, %{end_at: nil}), do: false
  defp ends_match?(a, b), do: within?(a.end_at, b.end_at, @duplicate_end_tolerance)

  # "canon(title_a) == canon(title_b), or either title is empty". An empty title
  # carries no evidence either way, so it does not veto a match.
  defp titles_match?(a, b) do
    canon_a = Canon.canon(a.title)
    canon_b = Canon.canon(b.title)
    canon_a == "" or canon_b == "" or canon_a == canon_b
  end

  defp billing_overlap?(a, b, now) do
    a.id != b.id and a.is_billable and b.is_billable and
      a.client_id != b.client_id and
      intersection_seconds(a, b, now) > @billing_overlap_minimum
  end

  defp intersection_seconds(a, b, now) do
    a_end = a.end_at || now
    b_end = b.end_at || now

    start = latest(a.start_at, b.start_at)
    finish = earliest(a_end, b_end)

    case DateTime.compare(finish, start) do
      :gt -> DateTime.diff(finish, start, :second)
      _ -> 0
    end
  end

  defp raise_pair(workspace_id, code, candidate, other, ctx) do
    # Both sides, each citing the other in `related_id`, so a client that only
    # holds one of the two still sees the pairing.
    raise_flag(workspace_id, other, code, candidate.id, ctx)
    raise_flag(workspace_id, candidate, code, other.id, ctx)
  end

  defp within?(a, b, seconds), do: abs(DateTime.diff(a, b, :second)) <= seconds

  defp latest(a, b), do: if(DateTime.compare(a, b) == :gt, do: a, else: b)
  defp earliest(a, b), do: if(DateTime.compare(a, b) == :lt, do: a, else: b)
end
