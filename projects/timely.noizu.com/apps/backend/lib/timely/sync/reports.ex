defmodule Timely.Sync.Reports do
  @moduledoc """
  `GET /api/v1/reports/summary` - the date-range rollup, computed server-side so
  a companion does not have to hold a full history locally.

  Four time figures are reported separately because conflating them is a
  credibility risk:

  - `elapsed_seconds` - the raw sum of span durations. Overlapping parallel work
    is counted once *per span*, so this can legitimately exceed wall-clock time.
  - `billable_seconds` - the same sum restricted to `is_billable`.
  - `weighted_billable_seconds` - overlap-corrected. For every instant covered
    by N live billable spans, each accrues 1/N of that instant, so summing this
    across every group never exceeds wall-clock time in the range. This is what
    stops the parallel-work model from double-billing: in the worked example
    (T5) two overlapping billable spans for one client contribute 50 contested
    minutes once, not twice.
  - `evidence_coverage` - the fraction of spans with at least one live
    screenshot row attached. Metadata counts; bytes are not required, because a
    local-only screenshot is still evidence that work happened.

  Open spans (`end` null) are clipped to `min(now, to)`.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  @excluded_review_states ~w(unreviewed needs_review)

  @doc "Builds the rollup for a workspace and range."
  # ⟦𓋴𓅓𓅓𓋴⟧ summary :: Builds the date-range rollup.
  def summary(workspace_id, opts) do
    from = Keyword.fetch!(opts, :from)
    to = Keyword.fetch!(opts, :to)
    group_by = Keyword.get(opts, :group_by, "project")
    time_zone = Keyword.get(opts, :time_zone, "UTC")
    include_unreviewed = Keyword.get(opts, :include_unreviewed, true)
    now = DateTime.utc_now()

    all_spans = load_spans(workspace_id, from, to, opts)

    needs_review_count =
      Enum.count(all_spans, &(&1.review_state in @excluded_review_states))

    # Excluded spans are dropped from the totals but still counted, and still
    # raise a warning: a report that quietly omits half the day is worse than
    # one that says so.
    spans =
      if include_unreviewed,
        do: all_spans,
        else: Enum.reject(all_spans, &(&1.review_state in @excluded_review_states))

    clipped = Enum.map(spans, &clip(&1, from, to, now))
    weights = weighted_billable(clipped)
    coverage = evidence_coverage(workspace_id, spans)

    groups = build_groups(clipped, weights, coverage, group_by, time_zone)

    %{
      "range" => %{
        "from" => DateTime.to_iso8601(from),
        "to" => DateTime.to_iso8601(to),
        "time_zone" => time_zone
      },
      "group_by" => group_by,
      "totals" => totals(clipped, weights, coverage, needs_review_count),
      "groups" => groups,
      "warnings" => warnings(all_spans, clipped, needs_review_count, workspace_id),
      "generated_at" => DateTime.to_iso8601(now),
      "server_revision" => Revisions.committed_watermark(workspace_id)
    }
  end

  # "All arithmetic is defined on **live** spans." A tombstoned span is not
  # billable work that happened, it is work that was retracted.
  defp load_spans(workspace_id, from, to, opts) do
    query =
      TimeSpan
      |> Workspace.scope(workspace_id)
      |> where([s], is_nil(s.deleted_at))
      # A span counts when it intersects the range at all, not only when it is
      # contained by it - a span that starts before `from` and runs into it is
      # part of that range's work.
      |> where([s], s.start_at < ^to)
      |> where([s], is_nil(s.end_at) or s.end_at > ^from)

    query =
      case Keyword.get(opts, :client_id) do
        nil -> query
        client_id -> where(query, [s], s.client_id == ^client_id)
      end

    query =
      case Keyword.get(opts, :project_id) do
        nil -> query
        project_id -> where(query, [s], s.project_id == ^project_id)
      end

    query =
      case Keyword.get(opts, :billable) do
        nil -> query
        billable -> where(query, [s], s.is_billable == ^billable)
      end

    Repo.all(query)
  end

  # An open span has no end yet, so it is worth exactly as much as has actually
  # elapsed: `min(now, to)`.
  defp clip(span, from, to, now) do
    span_end = span.end_at || now
    start = latest(span.start_at, from)
    finish = earliest(span_end, to)

    seconds =
      case DateTime.compare(finish, start) do
        :gt -> DateTime.diff(finish, start, :second)
        _ -> 0
      end

    %{
      span: span,
      start: start,
      finish: finish,
      seconds: seconds,
      open?: is_nil(span.end_at)
    }
  end

  # A sweep line over the billable intervals. Boundaries split the range into
  # elementary segments; inside a segment the set of covering spans is constant,
  # so each covering span accrues `duration / count` of it.
  defp weighted_billable(clipped) do
    billable = Enum.filter(clipped, &(&1.span.is_billable and &1.seconds > 0))

    boundaries =
      billable
      |> Enum.flat_map(fn %{start: start, finish: finish} -> [start, finish] end)
      |> Enum.uniq()
      |> Enum.sort(DateTime)

    empty = Map.new(billable, &{&1.span.id, 0.0})

    boundaries
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(empty, fn [segment_start, segment_end], acc ->
      duration = DateTime.diff(segment_end, segment_start, :second)

      covering =
        Enum.filter(billable, fn %{start: start, finish: finish} ->
          DateTime.compare(start, segment_start) != :gt and
            DateTime.compare(finish, segment_end) != :lt
        end)

      case covering do
        [] ->
          acc

        covering ->
          share = duration / length(covering)
          Enum.reduce(covering, acc, &Map.update!(&2, &1.span.id, fn v -> v + share end))
      end
    end)
  end

  # Metadata counts; bytes are not required. A byte-free workspace still has
  # full evidence coverage.
  defp evidence_coverage(workspace_id, spans) do
    span_ids = spans |> Enum.map(& &1.id) |> Enum.uniq()

    if span_ids == [] do
      MapSet.new()
    else
      Screenshot
      |> Workspace.scope(workspace_id)
      |> where([s], is_nil(s.deleted_at) and s.span_id in ^span_ids)
      |> select([s], s.span_id)
      |> distinct(true)
      |> Repo.all()
      |> MapSet.new()
    end
  end

  defp build_groups(clipped, weights, coverage, group_by, time_zone) do
    clipped
    |> Enum.group_by(&group_key(&1, group_by, time_zone))
    |> Enum.map(fn {{key, key_id, label, parent_label}, members} ->
      stats = aggregate(members, weights, coverage)

      %{
        "key" => key,
        "key_id" => key_id,
        "label" => label,
        "parent_label" => parent_label,
        "elapsed_seconds" => stats.elapsed,
        "billable_seconds" => stats.billable,
        "weighted_billable_seconds" => stats.weighted,
        "span_count" => stats.count,
        "evidence_coverage" => stats.coverage
      }
    end)
    |> Enum.sort_by(& &1["elapsed_seconds"], :desc)
  end

  # Spans with no project are legal and roll up under "Unassigned" rather than
  # being dropped - the time was still worked.
  defp group_key(%{span: span}, "project", _tz),
    do: {span.project_id || "unassigned", span.project_id, blank_to(span.project_name, "Unassigned"), span.client_name}

  defp group_key(%{span: span}, "client", _tz),
    do: {span.client_id || "unassigned", span.client_id, blank_to(span.client_name, "Unassigned"), nil}

  defp group_key(%{span: span}, "ticket", _tz),
    do: {span.ticket_id || "unassigned", span.ticket_id, blank_to(span.ticket_name, "Unassigned"), span.project_name}

  defp group_key(%{span: span}, "source", _tz), do: {span.source, nil, span.source, nil}

  defp group_key(%{start: start}, "day", time_zone) do
    date =
      case DateTime.shift_zone(start, time_zone) do
        {:ok, shifted} -> DateTime.to_date(shifted)
        # An unknown IANA zone falls back to UTC rather than failing the report.
        {:error, _reason} -> DateTime.to_date(start)
      end
      |> Date.to_iso8601()

    {date, nil, date, nil}
  end

  defp group_key(_member, _group_by, _tz), do: {"all", nil, "All", nil}

  defp aggregate(members, weights, coverage) do
    elapsed = members |> Enum.map(& &1.seconds) |> Enum.sum()
    billable = members |> Enum.filter(& &1.span.is_billable) |> Enum.map(& &1.seconds) |> Enum.sum()

    weighted =
      members
      |> Enum.map(&Map.get(weights, &1.span.id, 0.0))
      |> Enum.sum()
      |> round()

    covered = Enum.count(members, &MapSet.member?(coverage, &1.span.id))
    count = length(members)

    %{
      elapsed: elapsed,
      billable: billable,
      weighted: weighted,
      count: count,
      coverage: if(count == 0, do: 0.0, else: Float.round(covered / count, 4))
    }
  end

  defp totals(clipped, weights, coverage, needs_review_count) do
    stats = aggregate(clipped, weights, coverage)

    %{
      "elapsed_seconds" => stats.elapsed,
      "billable_seconds" => stats.billable,
      "non_billable_seconds" => stats.elapsed - stats.billable,
      "weighted_billable_seconds" => stats.weighted,
      "span_count" => stats.count,
      "needs_review_count" => needs_review_count,
      "evidence_coverage" => stats.coverage
    }
  end

  defp warnings(all_spans, clipped, needs_review_count, workspace_id) do
    open_count = Enum.count(clipped, & &1.open?)

    flag_counts =
      all_spans
      |> Enum.flat_map(&(&1.review_reasons || []))
      |> Enum.filter(&(&1["resolution"] == "pending"))
      |> Enum.frequencies_by(& &1["code"])

    locked_through = Timely.Sync.Policy.locked_through(workspace_id)

    []
    |> add_warning(
      needs_review_count > 0,
      "spans_need_review",
      "#{needs_review_count} spans are unreviewed or need review",
      needs_review_count
    )
    |> add_warning(
      Map.get(flag_counts, "billing_overlap", 0) > 0,
      "billing_overlap",
      "billable spans for different clients overlap in this range",
      Map.get(flag_counts, "billing_overlap", 0)
    )
    |> add_warning(
      Map.get(flag_counts, "suspected_duplicate", 0) > 0,
      "suspected_duplicate",
      "spans in this range are flagged as suspected duplicates",
      Map.get(flag_counts, "suspected_duplicate", 0)
    )
    |> add_warning(
      open_count > 0,
      "open_spans",
      "#{open_count} spans are still open and were clipped to now",
      open_count
    )
    |> add_warning(
      locked_through != nil,
      "locked_range",
      "part of this range is locked for editing",
      nil
    )
    |> Enum.reverse()
  end

  defp add_warning(warnings, false, _code, _message, _count), do: warnings

  defp add_warning(warnings, true, code, message, count) do
    warning = %{"code" => code, "message" => message}
    [if(count, do: Map.put(warning, "count", count), else: warning) | warnings]
  end

  defp blank_to(value, fallback) do
    case to_string(value || "") do
      "" -> fallback
      other -> other
    end
  end

  defp latest(a, b), do: if(DateTime.compare(a, b) == :gt, do: a, else: b)
  defp earliest(a, b), do: if(DateTime.compare(a, b) == :lt, do: a, else: b)
end
