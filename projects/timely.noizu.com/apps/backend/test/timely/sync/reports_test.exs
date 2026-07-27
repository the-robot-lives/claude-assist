defmodule Timely.Sync.ReportsTest do
  @moduledoc """
  `GET /api/v1/reports/summary`.

  The arithmetic that matters is `weighted_billable_seconds`: overlapping
  parallel work is the product, so `elapsed_seconds` may legitimately exceed
  wall-clock time, and the weighted figure is what stops the contested interval
  from being billed twice.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Sync.Reports

  setup do
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    base = DateTime.utc_now() |> DateTime.add(-24 * 3600, :second) |> truncate()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     base: base,
     from: DateTime.add(base, -3600, :second),
     to: DateTime.add(base, 24 * 3600, :second)}
  end

  defp truncate(dt), do: %{dt | microsecond: {0, 6}}

  defp summary(workspace_id, from, to, opts \\ []) do
    Reports.summary(workspace_id, Keyword.merge([from: from, to: to], opts))
  end

  describe "elapsed vs billable" do
    test "sums span durations and separates billable from not", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: true)

      span!(ws,
        start_at: DateTime.add(base, 7200, :second),
        end_at: DateTime.add(base, 9000, :second),
        is_billable: false
      )

      totals = summary(ws, from, to)["totals"]

      assert totals["elapsed_seconds"] == 5400
      assert totals["billable_seconds"] == 3600
      assert totals["non_billable_seconds"] == 1800
      assert totals["span_count"] == 2
    end

    test "elapsed counts overlapping work once per span and may exceed wall clock", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      # Two spans covering the same hour: two hours of elapsed, one hour of
      # wall clock. This is parallel work, not an error.
      for _ <- 1..2 do
        span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: true)
      end

      totals = summary(ws, from, to)["totals"]

      assert totals["elapsed_seconds"] == 7200
      assert totals["billable_seconds"] == 7200
    end
  end

  describe "weighted_billable_seconds" do
    test "splits a fully contested interval evenly", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      for _ <- 1..2 do
        span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: true)
      end

      totals = summary(ws, from, to)["totals"]

      # Each of the two spans accrues half of every instant, so the total is one
      # hour rather than two - and never exceeds wall-clock time in the range.
      assert totals["weighted_billable_seconds"] == 3600
    end

    test "splits only the contested portion, as in the worked example", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      # T5: a 105-minute span and a 50-minute span that overlaps its tail.
      span!(ws,
        title: "Redesign build",
        start_at: base,
        end_at: DateTime.add(base, 6300, :second),
        is_billable: true
      )

      span!(ws,
        title: "Client call",
        start_at: DateTime.add(base, 3300, :second),
        end_at: DateTime.add(base, 6300, :second),
        is_billable: true
      )

      totals = summary(ws, from, to)["totals"]

      # 6300 + 3000 elapsed...
      assert totals["elapsed_seconds"] == 9300
      # ...but the contested 3000 seconds are counted once, so the weighted
      # figure equals the 6300 seconds of wall clock actually covered.
      assert totals["weighted_billable_seconds"] == 6300
    end

    test "ignores non-billable spans entirely", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: true)
      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: false)

      totals = summary(ws, from, to)["totals"]

      # The non-billable span does not dilute the billable one's share.
      assert totals["weighted_billable_seconds"] == 3600
    end
  end

  describe "range handling" do
    test "clips a span that starts before the range", %{workspace_id: ws, base: base} do
      span!(ws, start_at: base, end_at: DateTime.add(base, 7200, :second), is_billable: true)

      from = DateTime.add(base, 3600, :second)
      to = DateTime.add(base, 7200, :second)

      # The span intersects the range, so it counts - but only for the part
      # inside it.
      assert summary(ws, from, to)["totals"]["elapsed_seconds"] == 3600
    end

    test "clips an open span to now and warns", %{workspace_id: ws} do
      start = DateTime.utc_now() |> DateTime.add(-1800, :second)
      span!(ws, start_at: start, end_at: nil)

      report =
        summary(ws, DateTime.add(start, -3600, :second), DateTime.utc_now() |> DateTime.add(3600, :second))

      assert report["totals"]["elapsed_seconds"] >= 1790
      assert report["totals"]["elapsed_seconds"] <= 1810
      assert Enum.any?(report["warnings"], &(&1["code"] == "open_spans"))
    end

    test "excludes spans entirely outside the range", %{workspace_id: ws, base: base} do
      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second))

      from = DateTime.add(base, 10_000, :second)
      to = DateTime.add(base, 20_000, :second)

      assert summary(ws, from, to)["totals"]["span_count"] == 0
    end

    test "excludes tombstoned spans", %{workspace_id: ws, base: base, from: from, to: to} do
      span = span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second))

      Repo.update_all(
        Timely.Schema.Tracking.TimeSpan |> Ecto.Query.where(id: ^span.id),
        set: [deleted_at: DateTime.utc_now()]
      )

      # All arithmetic is defined on live spans: a retracted span is not work
      # that happened.
      assert summary(ws, from, to)["totals"]["span_count"] == 0
    end
  end

  describe "grouping" do
    test "groups by project and puts unassigned time under Unassigned", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      project_id = Ecto.UUID.generate()

      span!(ws,
        start_at: base,
        end_at: DateTime.add(base, 3600, :second),
        project_id: project_id,
        project_name: "Redesign"
      )

      span!(ws,
        start_at: DateTime.add(base, 7200, :second),
        end_at: DateTime.add(base, 9000, :second)
      )

      groups = summary(ws, from, to, group_by: "project")["groups"]

      assert Enum.find(groups, &(&1["label"] == "Redesign"))["elapsed_seconds"] == 3600
      # Time with no project is still time worked; dropping it would silently
      # shrink the day.
      assert Enum.find(groups, &(&1["label"] == "Unassigned"))["elapsed_seconds"] == 1800
    end

    test "groups by day in the requested time zone", %{workspace_id: ws} do
      # 02:00 UTC is the previous day in Chicago.
      {:ok, at} = DateTime.new(~D[2026-07-20], ~T[02:00:00.000000], "Etc/UTC")
      span!(ws, start_at: at, end_at: DateTime.add(at, 3600, :second))

      utc =
        summary(ws, DateTime.add(at, -86_400, :second), DateTime.add(at, 86_400, :second),
          group_by: "day",
          time_zone: "UTC"
        )

      chicago =
        summary(ws, DateTime.add(at, -86_400, :second), DateTime.add(at, 86_400, :second),
          group_by: "day",
          time_zone: "America/Chicago"
        )

      assert hd(utc["groups"])["label"] == "2026-07-20"
      assert hd(chicago["groups"])["label"] == "2026-07-19"
    end

    test "groups by source", %{workspace_id: ws, base: base, from: from, to: to} do
      span!(ws, start_at: base, end_at: DateTime.add(base, 600, :second), source: "timer")
      span!(ws, start_at: base, end_at: DateTime.add(base, 900, :second), source: "manual")

      groups = summary(ws, from, to, group_by: "source")["groups"]

      assert Enum.find(groups, &(&1["key"] == "timer"))["elapsed_seconds"] == 600
      assert Enum.find(groups, &(&1["key"] == "manual"))["elapsed_seconds"] == 900
    end

    test "an unknown time zone falls back to UTC rather than failing the report", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      span!(ws, start_at: base, end_at: DateTime.add(base, 600, :second))

      assert %{"groups" => [_ | _]} =
               summary(ws, from, to, group_by: "day", time_zone: "Mars/Olympus_Mons")
    end
  end

  describe "filters" do
    test "restricts to one project", %{workspace_id: ws, base: base, from: from, to: to} do
      wanted = Ecto.UUID.generate()

      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), project_id: wanted)

      span!(ws,
        start_at: base,
        end_at: DateTime.add(base, 1800, :second),
        project_id: Ecto.UUID.generate()
      )

      assert summary(ws, from, to, project_id: wanted)["totals"]["elapsed_seconds"] == 3600
    end

    test "restricts to billable", %{workspace_id: ws, base: base, from: from, to: to} do
      span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second), is_billable: true)

      span!(ws,
        start_at: DateTime.add(base, 7200, :second),
        end_at: DateTime.add(base, 9000, :second),
        is_billable: false
      )

      assert summary(ws, from, to, billable: true)["totals"]["elapsed_seconds"] == 3600
    end

    test "include_unreviewed false excludes them from totals but still counts and warns", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      span!(ws,
        start_at: base,
        end_at: DateTime.add(base, 3600, :second),
        review_state: "reviewed"
      )

      span!(ws,
        start_at: DateTime.add(base, 7200, :second),
        end_at: DateTime.add(base, 9000, :second),
        review_state: "needs_review"
      )

      report = summary(ws, from, to, include_unreviewed: false)

      assert report["totals"]["elapsed_seconds"] == 3600
      # A report that quietly omits half the day is worse than one that says so.
      assert report["totals"]["needs_review_count"] == 1
      assert Enum.any?(report["warnings"], &(&1["code"] == "spans_need_review"))
    end
  end

  describe "evidence coverage" do
    test "counts metadata rows; bytes are not required", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      covered = span!(ws, start_at: base, end_at: DateTime.add(base, 3600, :second))
      _bare = span!(ws, start_at: DateTime.add(base, 7200, :second), end_at: DateTime.add(base, 9000, :second))

      # A local-only screenshot is still evidence that work happened.
      screenshot!(ws, span_id: covered.id, upload_state: "local_only")

      assert summary(ws, from, to)["totals"]["evidence_coverage"] == 0.5
    end

    test "is zero when nothing is attached", %{
      workspace_id: ws,
      base: base,
      from: from,
      to: to
    } do
      span!(ws, start_at: base, end_at: DateTime.add(base, 600, :second))

      assert summary(ws, from, to)["totals"]["evidence_coverage"] == 0.0
    end
  end

  describe "shape" do
    test "carries the range, group_by, generated_at and a revision", %{
      workspace_id: ws,
      from: from,
      to: to
    } do
      report = summary(ws, from, to)

      assert report["range"]["from"] == DateTime.to_iso8601(from)
      assert report["range"]["to"] == DateTime.to_iso8601(to)
      assert report["group_by"] == "project"
      assert is_binary(report["generated_at"])
      assert is_integer(report["server_revision"])
      assert is_list(report["warnings"])
    end

    test "an empty range is well formed rather than absent", %{
      workspace_id: ws,
      from: from,
      to: to
    } do
      report = summary(ws, from, to)

      assert report["groups"] == []
      assert report["totals"]["elapsed_seconds"] == 0
      assert report["totals"]["weighted_billable_seconds"] == 0
      assert report["totals"]["evidence_coverage"] == 0.0
    end
  end
end
