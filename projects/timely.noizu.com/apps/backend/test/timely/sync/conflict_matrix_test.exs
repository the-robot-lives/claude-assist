defmodule Timely.Sync.ConflictMatrixTest do
  @moduledoc """
  SYNC-PROTOCOL section 8.2, row by row.

  Each `describe` block names the matrix row it covers, so a change to the
  matrix has an obvious place to land and an unimplemented row is a visible
  hole rather than an absence nobody notices.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Evidence.CensoredScreenshot
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Evidence.VisionAnalysis
  alias Timely.Schema.Taxonomy
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Blobs
  alias Timely.Sync.Mutations
  alias Timely.Sync.Workspace

  setup do
    Blobs.Memory.reset()
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     ctx: ctx(workspace_id, user.id, device_id: device.id)}
  end

  defp push!(ctx, mutations) do
    {:ok, results} = Mutations.push(ctx, mutations)
    results
  end

  defp push_one!(ctx, mutation) do
    [result] = push!(ctx, [mutation])
    result
  end

  defp span_payload(overrides) do
    Map.merge(
      %{
        "id" => uuid7(),
        "title" => "Timeline canvas keyboard pass",
        "start" => iso(-3600),
        "end" => iso(-60),
        "source" => "timer",
        "is_billable" => false,
        "updated_at" => iso(-60)
      },
      overrides
    )
  end

  # -- row 1 ------------------------------------------------------------------

  describe "row 1: update vs update" do
    test "the later updated_at_effective wins", %{ctx: ctx} do
      id = uuid7()
      push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))

      # An edit composed an hour ago loses to one composed a minute ago,
      # regardless of the order they arrive in.
      push_one!(
        ctx,
        mutation(
          "time_span",
          "update",
          span_payload(%{"id" => id, "title" => "fresher", "updated_at" => iso(-60)})
        )
      )

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "title" => "staler", "updated_at" => iso(-3600)})
          )
        )

      # The losing mutation is still `applied` - it was processed and evaluated -
      # but the row it gets back is the winner's.
      assert result["status"] == "applied"
      assert result["entity"]["title"] == "fresher"
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, id).title == "fresher"
    end

    test "an exact tie is broken by the lexically greater origin_device_id", %{ctx: ctx} do
      id = uuid7()
      at = iso(-60)
      low = "019318a0-0000-7000-8000-000000000000"
      high = "019318a0-ffff-7000-8000-ffffffffffff"

      push_one!(
        ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => id,
            "title" => "from high device",
            "updated_at" => at,
            "origin_device_id" => high
          })
        )
      )

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => id,
              "title" => "from low device",
              "updated_at" => at,
              "origin_device_id" => low
            })
          )
        )

      # Both devices compute this same answer locally without asking the server,
      # which is the whole point of using a value they both already hold.
      assert result["status"] == "applied"
      assert result["entity"]["title"] == "from high device"
    end
  end

  # -- row 2 ------------------------------------------------------------------

  describe "row 2: update vs delete" do
    test "the tombstone is absorbing regardless of timestamps", %{ctx: ctx} do
      id = uuid7()
      push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))

      push_one!(
        ctx,
        mutation("time_span", "delete", %{
          "id" => id,
          "deleted_at" => iso(-600),
          "updated_at" => iso(-600)
        })
      )

      # The update is newer than the delete and still loses: a device that has
      # not seen the delete must not resurrect the row.
      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "title" => "resurrected", "updated_at" => iso()})
          )
        )

      assert result["status"] == "conflict"
      assert result["reason"] == "tombstoned"
      assert result["entity"]["deleted_at"] != nil
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, id) == nil
    end
  end

  # -- row 3 ------------------------------------------------------------------

  describe "row 3: delete vs delete" do
    test "is idempotent and retains the earliest deleted_at", %{ctx: ctx} do
      id = uuid7()
      push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))

      first =
        push_one!(
          ctx,
          mutation("time_span", "delete", %{"id" => id, "deleted_at" => iso(-600)})
        )

      second =
        push_one!(
          ctx,
          mutation("time_span", "delete", %{"id" => id, "deleted_at" => iso()})
        )

      assert first["status"] == "applied"
      assert second["status"] == "applied"
      # The second delete must not move the tombstone forward.
      assert second["entity"]["deleted_at"] == first["entity"]["deleted_at"]
    end
  end

  # -- row 4 ------------------------------------------------------------------

  describe "row 4: create with an existing id" do
    test "degrades to an update rather than producing a second row", %{ctx: ctx} do
      id = uuid7()
      push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{"id" => id, "title" => "second create", "updated_at" => iso()})
          )
        )

      assert result["status"] == "applied"
      assert result["entity"]["title"] == "second create"

      # This is why locally minted primary keys are a correctness property and
      # not merely an offline convenience: a replay past the ledger's retention
      # window still converges on one row.
      assert Repo.aggregate(
               TimeSpan |> Workspace.scope(ctx.workspace_id) |> Ecto.Query.where(id: ^id),
               :count
             ) == 1
    end
  end

  # -- row 5 ------------------------------------------------------------------

  describe "row 5: updated_at far in the future" do
    test "is clamped to receipt and raises low_confidence", %{ctx: ctx} do
      id = uuid7()

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            # A device whose clock is set five years fast would otherwise win
            # every conflict until 2031.
            span_payload(%{"id" => id, "updated_at" => iso(5 * 365 * 24 * 3600)})
          )
        )

      assert result["status"] == "applied"
      assert result["stale_base"]

      row = Workspace.fetch_live(TimeSpan, ctx.workspace_id, id)
      # The clamp: updated_at_effective never exceeds receipt.
      assert DateTime.compare(row.updated_at_effective, DateTime.utc_now()) != :gt
      assert row.review_state == "needs_review"
      assert Enum.any?(row.review_reasons, &(&1["code"] == "low_confidence"))
      assert Enum.all?(row.review_reasons, &(&1["raised_by"] == "server"))
    end

    test "an ordinary offline delay is clamped without being flagged", %{ctx: ctx} do
      id = uuid7()

      # Composed on Monday, pushed on Friday: clamped to Friday, which is when
      # the rest of the system first learned of it, and not suspicious.
      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{"id" => id, "updated_at" => iso(-4 * 24 * 3600)})
          )
        )

      assert result["status"] == "applied"
      row = Workspace.fetch_live(TimeSpan, ctx.workspace_id, id)
      refute Enum.any?(row.review_reasons, &(&1["code"] == "low_confidence"))
    end
  end

  # -- rows 6 and 7 -----------------------------------------------------------

  describe "rows 6 and 7: reopening a closed span" do
    test "row 6: a stale base cannot set end to null", %{ctx: ctx} do
      id = uuid7()
      created = push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))
      current = created["entity"]["server_revision"]

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "end" => nil, "updated_at" => iso()}),
            base_revision: current - 1
          )
        )

      # A closed span is evidence. A device that has not seen the close must not
      # undo it.
      assert result["status"] == "rejected"
      assert result["reason"] == "span_reopen_forbidden"
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, id).end_at != nil
    end

    test "row 7: a current base may reopen deliberately", %{ctx: ctx} do
      id = uuid7()
      created = push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))
      current = created["entity"]["server_revision"]

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "end" => nil, "updated_at" => iso()}),
            base_revision: current
          )
        )

      # A user reopening a span they can currently see is legitimate.
      assert result["status"] == "applied"
      assert result["entity"]["end"] == nil
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, id).end_at == nil
    end

    test "an absent end key is not a reopen", %{ctx: ctx} do
      id = uuid7()
      push_one!(ctx, mutation("time_span", "create", span_payload(%{"id" => id})))

      # `end: null` reopens; `end` absent leaves the close alone. Conflating the
      # two would make every partial update a reopen attempt.
      payload = span_payload(%{"id" => id, "updated_at" => iso()}) |> Map.delete("end")
      result = push_one!(ctx, mutation("time_span", "update", payload, base_revision: 1))

      assert result["status"] == "applied"
    end
  end

  # -- rows 8, 9 and 10 -------------------------------------------------------

  describe "row 8: overlapping spans" do
    test "are not a conflict and are never merged, trimmed or rejected", %{ctx: ctx} do
      base = DateTime.utc_now() |> DateTime.add(-7200, :second)

      a = uuid7()
      b = uuid7()

      push_one!(
        ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => a,
            "title" => "Redesign build",
            "start" => DateTime.to_iso8601(base),
            "end" => DateTime.to_iso8601(DateTime.add(base, 3600, :second))
          })
        )
      )

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => b,
              "title" => "Client call",
              "start" => DateTime.to_iso8601(DateTime.add(base, 1800, :second)),
              "end" => DateTime.to_iso8601(DateTime.add(base, 5400, :second))
            })
          )
        )

      # Parallel work is the product, not an error.
      assert result["status"] == "applied"
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, a) != nil
      assert Workspace.fetch_live(TimeSpan, ctx.workspace_id, b) != nil
    end
  end

  describe "row 9: billable overlap across different clients" do
    test "applies and flags billing_overlap on both rows", %{ctx: ctx} do
      base = DateTime.utc_now() |> DateTime.add(-7200, :second)
      a = uuid7()
      b = uuid7()

      push_one!(
        ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => a,
            "title" => "Acme work",
            "client_name" => "Acme",
            "is_billable" => true,
            "start" => DateTime.to_iso8601(base),
            "end" => DateTime.to_iso8601(DateTime.add(base, 3600, :second))
          })
        )
      )

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => b,
              "title" => "Globex work",
              "client_name" => "Globex",
              "is_billable" => true,
              "start" => DateTime.to_iso8601(DateTime.add(base, 600, :second)),
              "end" => DateTime.to_iso8601(DateTime.add(base, 3600, :second))
            })
          )
        )

      assert result["status"] == "applied"

      row_a = Workspace.fetch_live(TimeSpan, ctx.workspace_id, a)
      row_b = Workspace.fetch_live(TimeSpan, ctx.workspace_id, b)

      # Double-billing risk is a review item, not an error, and it is raised on
      # both rows so whichever one the user opens shows it.
      assert flagged?(row_a, "billing_overlap")
      assert flagged?(row_b, "billing_overlap")
      assert row_a.review_state == "needs_review"
      assert row_b.review_state == "needs_review"
    end

    test "does not fire for two billable spans resolving to the same client", %{ctx: ctx} do
      base = DateTime.utc_now() |> DateTime.add(-7200, :second)
      a = uuid7()
      b = uuid7()

      for {id, offset} <- [{a, 0}, {b, 600}] do
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => id,
              "title" => "Acme #{offset}",
              "client_name" => "Acme",
              "is_billable" => true,
              "start" => DateTime.to_iso8601(DateTime.add(base, offset, :second)),
              "end" => DateTime.to_iso8601(DateTime.add(base, 3600, :second))
            })
          )
        )
      end

      # This is the T5 case: overlapping billable work for one client is the
      # parallel-work model behaving correctly, and the weighted rollup already
      # stops the contested interval from being billed twice.
      refute flagged?(Workspace.fetch_live(TimeSpan, ctx.workspace_id, a), "billing_overlap")
      refute flagged?(Workspace.fetch_live(TimeSpan, ctx.workspace_id, b), "billing_overlap")
    end
  end

  describe "row 10: suspected duplicates" do
    test "flags both rows, each citing the other, and merges nothing", %{ctx: ctx} do
      start = DateTime.utc_now() |> DateTime.add(-3600, :second)
      finish = DateTime.add(start, 1800, :second)
      a = uuid7()
      b = uuid7()

      for id <- [a, b] do
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => id,
              "title" => "Timeline canvas",
              # Within the 120s start and end tolerances.
              "start" => DateTime.to_iso8601(DateTime.add(start, 30, :second)),
              "end" => DateTime.to_iso8601(DateTime.add(finish, 30, :second))
            })
          )
        )
      end

      row_a = Workspace.fetch_live(TimeSpan, ctx.workspace_id, a)
      row_b = Workspace.fetch_live(TimeSpan, ctx.workspace_id, b)

      assert flagged?(row_a, "suspected_duplicate")
      assert flagged?(row_b, "suspected_duplicate")
      assert related_ids(row_a, "suspected_duplicate") == [b]
      assert related_ids(row_b, "suspected_duplicate") == [a]

      # Never auto-merged: both rows survive intact.
      assert row_a.id != row_b.id
      assert row_a.title == row_b.title
    end

    test "does not flag spans more than the tolerance apart", %{ctx: ctx} do
      start = DateTime.utc_now() |> DateTime.add(-7200, :second)
      a = uuid7()
      b = uuid7()

      push_one!(
        ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => a,
            "title" => "Client call",
            "start" => DateTime.to_iso8601(start),
            "end" => DateTime.to_iso8601(DateTime.add(start, 3000, :second))
          })
        )
      )

      # 55 minutes apart, which is the T5 recreation case: not a duplicate.
      push_one!(
        ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => b,
            "title" => "Client call",
            "start" => DateTime.to_iso8601(DateTime.add(start, 3300, :second)),
            "end" => DateTime.to_iso8601(DateTime.add(start, 6000, :second))
          })
        )
      )

      refute flagged?(Workspace.fetch_live(TimeSpan, ctx.workspace_id, a), "suspected_duplicate")
    end

    test "re-running detection does not accumulate duplicate flags", %{ctx: ctx} do
      start = DateTime.utc_now() |> DateTime.add(-3600, :second)
      a = uuid7()
      b = uuid7()

      for id <- [a, b] do
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => id,
              "title" => "Same work",
              "start" => DateTime.to_iso8601(start),
              "end" => DateTime.to_iso8601(DateTime.add(start, 600, :second))
            })
          )
        )
      end

      for _ <- 1..3 do
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => a,
              "title" => "Same work",
              "start" => DateTime.to_iso8601(start),
              "end" => DateTime.to_iso8601(DateTime.add(start, 600, :second)),
              "updated_at" => iso()
            })
          )
        )
      end

      row_a = Workspace.fetch_live(TimeSpan, ctx.workspace_id, a)
      assert length(related_ids(row_a, "suspected_duplicate")) == 1
    end
  end

  # -- row 11 -----------------------------------------------------------------

  describe "row 11: locked days" do
    test "an update to a span with locked_at is rejected", %{ctx: ctx, workspace_id: workspace_id} do
      span = span!(workspace_id, locked_at: DateTime.utc_now())

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => span.id, "title" => "edited", "updated_at" => iso()})
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end

    test "a span starting before locked_through is rejected", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      set_policy!(workspace_id, %{"locked_through" => iso(-60)})
      span = span!(workspace_id, start_at: DateTime.utc_now() |> DateTime.add(-7200, :second))

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => span.id, "title" => "edited", "updated_at" => iso()})
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end

    test "an admin clearing the lock reopens and raises reopened_after_approval", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      span = span!(workspace_id, locked_at: DateTime.utc_now())

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "title" => "reopened",
              "locked_at" => nil,
              "updated_at" => iso()
            }),
            # The escape hatch requires a current base_revision, so a stale
            # admin cannot clear a lock they have never seen. See
            # Timely.Sync.AdjudicationTest for the rejection side.
            base_revision: span.server_revision
          )
        )

      assert result["status"] == "applied"

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.locked_at == nil
      # Reopening an approved day is an auditable event, not a silent edit.
      assert flagged?(row, "reopened_after_approval")
    end

    test "a non-admin cannot clear the lock", %{workspace_id: workspace_id, user: user} do
      span = span!(workspace_id, locked_at: DateTime.utc_now())
      viewer_ctx = ctx(workspace_id, user.id, admin: false)

      result =
        push_one!(
          viewer_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => span.id, "locked_at" => nil, "updated_at" => iso()})
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end
  end

  # -- rows 12 and 13 ---------------------------------------------------------

  describe "rows 12 and 13: duplicate taxonomy names" do
    test "row 12: a create whose canonical name maps to a different id conflicts", %{ctx: ctx} do
      # "Acme" was renamed to "Acme Corp" on the server.
      renamed_id = Timely.Sync.Canon.client_id(ctx.workspace_id, "Acme")

      push_one!(
        ctx,
        mutation("client", "create", %{
          "id" => renamed_id,
          "name" => "Acme Corp",
          "updated_at" => iso()
        })
      )

      # An offline device vivifies the *new* name and computes a *new* id.
      colliding_id = Timely.Sync.Canon.client_id(ctx.workspace_id, "Acme Corp")

      result =
        push_one!(
          ctx,
          mutation("client", "create", %{
            "id" => colliding_id,
            "name" => "Acme Corp",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "conflict"
      assert result["reason"] == "duplicate_name"
      # The client adopts this row and rewrites its local references to it.
      assert result["entity"]["id"] == renamed_id

      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(ctx.workspace_id), :count) == 1
    end

    test "row 13: renaming onto a taken canonical name conflicts", %{ctx: ctx} do
      acme = Timely.Sync.Canon.client_id(ctx.workspace_id, "Acme")
      globex = Timely.Sync.Canon.client_id(ctx.workspace_id, "Globex")

      push_one!(
        ctx,
        mutation("client", "create", %{"id" => acme, "name" => "Acme", "updated_at" => iso()})
      )

      push_one!(
        ctx,
        mutation("client", "create", %{"id" => globex, "name" => "Globex", "updated_at" => iso()})
      )

      result =
        push_one!(
          ctx,
          mutation("client", "update", %{
            "id" => globex,
            "name" => "Acme",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "conflict"
      assert result["reason"] == "duplicate_name"
      assert result["entity"]["id"] == acme
    end

    test "the reverse direction is an idempotent no-op that lands on the renamed row", %{ctx: ctx} do
      # A stale device vivifying the *old* name computes the *old* id, which
      # still exists because ids are stable across renames.
      id = Timely.Sync.Canon.client_id(ctx.workspace_id, "Acme")

      push_one!(
        ctx,
        mutation("client", "create", %{"id" => id, "name" => "Acme Corp", "updated_at" => iso()})
      )

      result =
        push_one!(
          ctx,
          mutation("client", "create", %{"id" => id, "name" => "Acme", "updated_at" => iso(-3600)})
        )

      assert result["status"] == "applied"
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(ctx.workspace_id), :count) == 1
    end

    test "a name that canonicalizes to empty is not an entity", %{ctx: ctx} do
      result =
        push_one!(
          ctx,
          mutation("client", "create", %{
            "id" => uuid7(),
            "name" => "   ​ ",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "validation_failed"
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(ctx.workspace_id), :count) == 0
    end
  end

  # -- rows 14 and 15 ---------------------------------------------------------

  describe "rows 14 and 15: append-only entities" do
    test "row 14: any vision_analysis update is rejected as immutable", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      screenshot = screenshot!(workspace_id)
      analysis = vision_analysis!(workspace_id, screenshot.id)

      result =
        push_one!(
          ctx,
          mutation("vision_analysis", "update", %{
            "id" => analysis.id,
            "screenshot_id" => screenshot.id,
            "status_update" => "rewritten",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "immutable_entity"

      # Re-analysis creates a new row instead.
      assert Workspace.fetch_live(VisionAnalysis, workspace_id, analysis.id).status_update ==
               analysis.status_update
    end

    test "row 15: any censored_screenshot update is rejected as immutable", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      screenshot = screenshot!(workspace_id)
      id = uuid7()

      push_one!(
        ctx,
        mutation("censored_screenshot", "create", %{
          "id" => id,
          "screenshot_id" => screenshot.id,
          "captured_at" => iso(-600),
          "censored_at" => iso(-60),
          "category" => "financial",
          "confidence" => 0.95,
          "updated_at" => iso()
        })
      )

      result =
        push_one!(
          ctx,
          mutation("censored_screenshot", "update", %{
            "id" => id,
            "screenshot_id" => screenshot.id,
            "reason" => "changed my mind",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "immutable_entity"
    end
  end

  # -- row 16 -----------------------------------------------------------------

  describe "row 16: the censorship cascade" do
    test "tombstones the screenshot and its analyses and purges the blob", %{
      ctx: ctx,
      workspace_id: workspace_id,
      device: device
    } do
      set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})
      {:ok, _} = Timely.Sync.Devices.update(workspace_id, ctx.user_id, device.id, %{"local_only_screenshots" => false})

      screenshot = screenshot!(workspace_id)
      analysis = vision_analysis!(workspace_id, screenshot.id)

      {:ok, uploaded} = Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")
      assert uploaded.upload_state == "uploaded"

      result =
        push_one!(
          ctx,
          mutation("censored_screenshot", "create", %{
            "id" => uuid7(),
            "screenshot_id" => screenshot.id,
            "captured_at" => iso(-600),
            "censored_at" => iso(-60),
            "category" => "financial",
            "confidence" => 0.95,
            "deleted_local_file" => true,
            "updated_at" => iso()
          })
        )

      assert result["status"] == "applied"

      kinds = Enum.map(result["side_effects"], & &1["entity"])
      assert "screenshot" in kinds
      assert "vision_analysis" in kinds

      # Metadata rows survive as tombstones - the timeline does not develop
      # holes - but the bytes are gone.
      stored = Repo.get(Screenshot, screenshot.id)
      assert stored.deleted_at != nil
      assert stored.upload_state == "purged"
      assert stored.blob_storage_key == nil
      assert Repo.get(VisionAnalysis, analysis.id).deleted_at != nil
      assert {:error, :not_available} = Blobs.download(workspace_id, screenshot.id)
    end

    test "the censorship record itself survives as a live row", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      screenshot = screenshot!(workspace_id)
      id = uuid7()

      push_one!(
        ctx,
        mutation("censored_screenshot", "create", %{
          "id" => id,
          "screenshot_id" => screenshot.id,
          "captured_at" => iso(-600),
          "censored_at" => iso(-60),
          "category" => "medical",
          "confidence" => 0.9,
          "updated_at" => iso()
        })
      )

      assert Workspace.fetch_live(CensoredScreenshot, workspace_id, id) != nil
    end
  end

  # -- row 17 -----------------------------------------------------------------

  describe "row 17: server-owned screenshot fields" do
    test "client attempts to set upload_state and blob_* are ignored, not rejected", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      id = uuid7()

      result =
        push_one!(
          ctx,
          mutation("screenshot", "create", %{
            "id" => id,
            "captured_at" => iso(-600),
            "file_name" => "timely-test.png",
            "active_app_name" => "Xcode",
            # All of these are the server's to decide.
            "upload_state" => "uploaded",
            "blob_content_hash" => String.duplicate("a", 64),
            "blob_byte_size" => 999_999,
            "updated_at" => iso()
          })
        )

      assert result["status"] == "applied"

      row = Workspace.fetch_live(Screenshot, workspace_id, id)
      assert row.upload_state == "local_only"
      assert row.blob_content_hash == nil
      assert row.blob_byte_size == nil
      # The metadata the client legitimately owns did land.
      assert row.active_app_name == "Xcode"
    end
  end

  # -- row 18 -----------------------------------------------------------------

  describe "row 18: device ownership" do
    test "a mutation from a device other than the subject is rejected", %{
      ctx: ctx,
      workspace_id: workspace_id,
      user: user
    } do
      other = device!(workspace_id, user.id, platform: "android")

      result =
        push_one!(
          ctx,
          mutation("device", "update", %{
            "id" => other.id,
            "name" => "renamed by someone else",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "not_device_owner"
    end

    test "the subject device may mutate its own row", %{ctx: ctx, device: device} do
      result =
        push_one!(
          ctx,
          mutation("device", "update", %{
            "id" => device.id,
            "user_id" => device.user_id,
            "platform" => "macos",
            "name" => "Keith's MacBook Pro",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "applied"
      assert result["entity"]["name"] == "Keith's MacBook Pro"
    end
  end

  # -- row 19 -----------------------------------------------------------------

  describe "row 19: workspace policy" do
    test "a non-admin mutation is rejected as permission_denied", %{
      workspace_id: workspace_id,
      user: user
    } do
      viewer_ctx = ctx(workspace_id, user.id, admin: false)

      result =
        push_one!(
          viewer_ctx,
          mutation("workspace_policy", "update", %{
            "id" => workspace_id,
            "kind" => "workspace_policy",
            "screenshot_upload_allowed" => true,
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "permission_denied"
      # The gate stayed closed, which is the part that matters.
      refute Timely.Sync.Policy.workspace_policy(workspace_id)["screenshot_upload_allowed"]
    end

    test "an admin may open the gate", %{ctx: ctx, workspace_id: workspace_id} do
      result =
        push_one!(
          ctx,
          mutation("workspace_policy", "update", %{
            "id" => workspace_id,
            "kind" => "workspace_policy",
            "screenshot_upload_allowed" => true,
            "updated_at" => iso()
          })
        )

      assert result["status"] == "applied"
      assert Timely.Sync.Policy.workspace_policy(workspace_id)["screenshot_upload_allowed"]
    end
  end

  # -- row 20 -----------------------------------------------------------------

  describe "row 20: user settings" do
    test "resolve by LWW on the whole document", %{ctx: ctx, workspace_id: workspace_id, user: user} do
      id = Timely.Sync.Canon.user_settings_id(workspace_id, user.id)

      push_one!(
        ctx,
        mutation("user_settings", "update", %{
          "id" => id,
          "kind" => "user_settings",
          "user_id" => user.id,
          "pomodoro_work_minutes" => 50,
          "updated_at" => iso(-60)
        })
      )

      result =
        push_one!(
          ctx,
          mutation("user_settings", "update", %{
            "id" => id,
            "kind" => "user_settings",
            "user_id" => user.id,
            "screenshot_interval_minutes" => 10,
            "updated_at" => iso(-3600)
          })
        )

      # Whole-document LWW: the stale write loses everything, including the
      # field the winner never mentioned. That is entity-level LWW behaving as
      # specified, and section 13 records field-level merge as the intended v2.
      assert result["status"] == "applied"
      assert result["entity"]["pomodoro_work_minutes"] == 50
      assert result["entity"]["screenshot_interval_minutes"] == 5
    end
  end

  # -- row 21 -----------------------------------------------------------------

  describe "row 21: workspace mismatch" do
    test "a payload naming a different workspace is rejected", %{ctx: ctx} do
      other_workspace = workspace!()

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{"id" => uuid7(), "workspace_id" => other_workspace})
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "workspace_mismatch"
    end

    test "a payload naming the request's own workspace is fine", %{ctx: ctx} do
      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{"id" => uuid7(), "workspace_id" => ctx.workspace_id})
          )
        )

      assert result["status"] == "applied"
    end
  end

  # -- row 22 -----------------------------------------------------------------

  describe "row 22: atomic batches" do
    test "one bad member rolls the whole batch back and answers 409", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      locked = span!(workspace_id, locked_at: DateTime.utc_now())
      good_id = uuid7()

      atomic_ctx = Map.put(ctx, :atomic, true)

      {:conflict, results} =
        Mutations.push(atomic_ctx, [
          mutation("time_span", "create", span_payload(%{"id" => good_id})),
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => locked.id, "title" => "edit", "updated_at" => iso()})
          )
        ])

      assert Enum.all?(results, &(&1["status"] == "rejected"))
      assert Enum.all?(results, &(&1["reason"] == "batch_rolled_back"))

      # Nothing was written - not even the member that would have succeeded.
      assert Workspace.fetch_live(TimeSpan, workspace_id, good_id) == nil
    end

    test "a split lands whole: N creates plus one delete of the original", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      original = span!(workspace_id, title: "Whole morning")
      first = uuid7()
      second = uuid7()

      atomic_ctx = Map.put(ctx, :atomic, true)

      {:ok, results} =
        Mutations.push(atomic_ctx, [
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => first,
              "title" => "Redesign build",
              "derived_from_span_ids" => [original.id]
            })
          ),
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => second,
              "title" => "Client call",
              "derived_from_span_ids" => [original.id]
            })
          ),
          mutation("time_span", "delete", %{"id" => original.id, "deleted_at" => iso()})
        ])

      assert Enum.all?(results, &(&1["status"] == "applied"))
      assert Workspace.fetch_live(TimeSpan, workspace_id, first) != nil
      assert Workspace.fetch_live(TimeSpan, workspace_id, second) != nil
      assert Workspace.fetch_live(TimeSpan, workspace_id, original.id) == nil

      # The lineage survives the split, which is what makes it reversible.
      assert Workspace.fetch_live(TimeSpan, workspace_id, first).derived_from_span_ids ==
               [original.id]
    end

    test "an atomic batch over 50 mutations is refused", %{ctx: ctx} do
      atomic_ctx = Map.put(ctx, :atomic, true)

      mutations =
        for _ <- 1..51,
            do: mutation("time_span", "create", span_payload(%{"id" => uuid7()}))

      assert {:error, :batch_too_large} = Mutations.push(atomic_ctx, mutations)
    end

    test "a batch over 200 mutations is refused", %{ctx: ctx} do
      mutations =
        for _ <- 1..201,
            do: mutation("time_span", "create", span_payload(%{"id" => uuid7()}))

      assert {:error, :batch_too_large} = Mutations.push(ctx, mutations)
    end
  end

  # -- entity_kind discriminator ----------------------------------------------

  describe "entity_kind discriminator" do
    # `results` is one flat array, so a client that cannot tell which kind of
    # row `entity` holds has to infer it from the field shape - and guessing
    # wrong means writing a time_span into the clients table.
    test "tags every result with the EntityKind it acted on", %{
      ctx: ctx,
      workspace_id: workspace_id,
      device: device
    } do
      screenshot = screenshot!(workspace_id)
      client_id = Timely.Sync.Canon.client_id(workspace_id, "Acme")

      results =
        push!(ctx, [
          mutation("client", "create", %{
            "id" => client_id,
            "name" => "Acme",
            "updated_at" => iso()
          }),
          mutation("time_span", "create", span_payload(%{"id" => uuid7()})),
          mutation("screenshot", "update", %{
            "id" => screenshot.id,
            "captured_at" => iso(-600),
            "updated_at" => iso()
          }),
          mutation("device", "update", %{
            "id" => device.id,
            "user_id" => device.user_id,
            "platform" => "macos",
            "name" => "Renamed",
            "updated_at" => iso()
          })
        ])

      assert Enum.map(results, & &1["entity_kind"]) ==
               ["client", "time_span", "screenshot", "device"]

      # And the tag really does describe the echoed row.
      [client_result, span_result | _] = results
      assert client_result["entity"]["canonical_name"] == "acme"
      assert Map.has_key?(span_result["entity"], "start")
    end

    test "is present on rejected results, where entity is null", %{ctx: ctx} do
      result =
        push_one!(
          ctx,
          mutation("vision_analysis", "update", %{
            "id" => uuid7(),
            "screenshot_id" => uuid7(),
            "updated_at" => iso()
          })
        )

      assert result["status"] == "rejected"
      assert result["entity"] == nil
      # The client still needs to route this back to the mutation it queued.
      assert result["entity_kind"] == "vision_analysis"
    end

    test "is present on conflict results", %{ctx: ctx} do
      acme = Timely.Sync.Canon.client_id(ctx.workspace_id, "Acme")

      push_one!(
        ctx,
        mutation("client", "create", %{"id" => acme, "name" => "Acme", "updated_at" => iso()})
      )

      result =
        push_one!(
          ctx,
          mutation("client", "create", %{
            "id" => uuid7(),
            "name" => "acme",
            "updated_at" => iso()
          })
        )

      assert result["status"] == "conflict"
      assert result["entity_kind"] == "client"
    end

    test "is null rather than an echo when the entity kind is unknown", %{ctx: ctx} do
      result = push_one!(ctx, mutation("wormhole", "create", %{"id" => uuid7()}))

      assert result["reason"] == "unknown_entity"
      # Echoing "wormhole" back would hand the client a value outside the enum.
      assert result["entity_kind"] == nil
    end

    test "survives a replay verbatim", %{ctx: ctx} do
      m = mutation("time_span", "create", span_payload(%{"id" => uuid7()}))

      first = push_one!(ctx, m)
      second = push_one!(ctx, m)

      assert second["replayed"] == true
      assert second["entity_kind"] == first["entity_kind"]
      assert second["entity_kind"] == "time_span"
    end

    test "survives an atomic rollback", %{ctx: ctx, workspace_id: workspace_id} do
      locked = span!(workspace_id, locked_at: DateTime.utc_now())
      atomic_ctx = Map.put(ctx, :atomic, true)

      {:conflict, results} =
        Mutations.push(atomic_ctx, [
          mutation("client", "create", %{
            "id" => Timely.Sync.Canon.client_id(workspace_id, "Acme"),
            "name" => "Acme",
            "updated_at" => iso()
          }),
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => locked.id, "updated_at" => iso()})
          )
        ])

      assert Enum.map(results, & &1["entity_kind"]) == ["client", "time_span"]
    end

    test "side effects carry their own kind alongside the row", %{ctx: ctx} do
      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => uuid7(),
              "client_name" => "Acme",
              "project_name" => "Redesign"
            })
          )
        )

      # SideEffect already pairs the kind with the row, which is the pattern
      # `entity_kind` follows on the result envelope.
      kinds = Enum.map(result["side_effects"], & &1["entity"])
      assert kinds == ["client", "project"]

      for effect <- result["side_effects"] do
        assert effect["entity"] in Timely.Sync.Vocabulary.entity_kinds()
        assert is_map(effect["row"])
      end
    end
  end

  # -- unknown entity ---------------------------------------------------------

  describe "validation" do
    test "an unknown entity kind is rejected", %{ctx: ctx} do
      result = push_one!(ctx, mutation("wormhole", "create", %{"id" => uuid7()}))

      assert result["status"] == "rejected"
      assert result["reason"] == "unknown_entity"
    end

    test "a non-uuid payload id is rejected", %{ctx: ctx} do
      result = push_one!(ctx, mutation("time_span", "create", %{"id" => "not-a-uuid"}))

      assert result["status"] == "rejected"
      assert result["reason"] == "validation_failed"
    end

    test "an empty batch is refused", %{ctx: ctx} do
      assert {:error, :empty_batch} = Mutations.push(ctx, [])
    end
  end

  defp flagged?(row, code) do
    Enum.any?(row.review_reasons || [], &(&1["code"] == code and &1["resolution"] == "pending"))
  end

  defp related_ids(row, code) do
    (row.review_reasons || [])
    |> Enum.filter(&(&1["code"] == code))
    |> Enum.map(& &1["related_id"])
    |> Enum.reject(&is_nil/1)
  end
end
