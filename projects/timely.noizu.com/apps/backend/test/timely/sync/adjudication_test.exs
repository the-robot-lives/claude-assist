defmodule Timely.Sync.AdjudicationTest do
  @moduledoc """
  Two guards that read a payload's *intent* and, until now, failed to ask
  whether the actor could have known what they were overriding.

  Both were found by client authors reasoning about the server from the outside.

  1. The LWW tie-break adjudicated on the raw payload while storage used a
     derived value, so a client that omitted `origin_device_id` lost every
     exact-timestamp tie - and two clients with different serialization habits
     computed different winners from the same two versions, which is the exact
     determinism §8.1 claims to provide.

  2. `guard_locked` checked that the actor was an admin but never that they had
     seen the lock, while the structurally identical reopen guard did.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Mutations
  alias Timely.Sync.Workspace

  # Chosen so the ordering is unambiguous: `low` sorts below `high` lexically,
  # and both sort ABOVE the empty string - which is the whole point of the first
  # group of tests.
  @low "019318a0-0000-7000-8000-000000000000"
  @high "019318a0-ffff-7000-8000-ffffffffffff"

  setup do
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok, workspace_id: workspace_id, user: user, device: device}
  end

  defp push_one!(ctx, mutation) do
    {:ok, [result]} = Mutations.push(ctx, [mutation])
    result
  end

  # Deliberately in the PAST. `updated_at` is clamped to
  # `min(updated_at, received_at)`, so a future timestamp is replaced by the
  # server's clock at receipt - and two pushes then carry two DIFFERENT
  # effective times, milliseconds apart. That silently turns a tie-break test
  # into a plain timestamp comparison and lets it pass for the wrong reason.
  # A past instant survives the clamp untouched, so the tie is exact and the
  # tie-break is genuinely what decides.
  @tie_instant "2026-07-25T10:00:00.000000Z"

  defp span_payload(overrides) do
    Map.merge(
      %{
        "id" => uuid7(),
        "title" => "Work",
        "start" => "2026-07-25T09:00:00.000000Z",
        "end" => @tie_instant,
        "source" => "timer",
        "updated_at" => @tie_instant
      },
      overrides
    )
  end

  describe "the LWW tie-break adjudicates on the DERIVED origin_device_id" do
    test "an omitted origin_device_id is substituted with the pushing device", %{
      workspace_id: workspace_id,
      user: user
    } do
      id = uuid7()
      at = @tie_instant

      # The existing row was authored by the LOW-sorting device.
      low_ctx = ctx(workspace_id, user.id, device_id: @low)

      push_one!(
        low_ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{"id" => id, "title" => "from low", "updated_at" => at})
        )
      )

      # A HIGH-sorting device pushes at the identical timestamp and OMITS the
      # field. Before the fix this compared "" against the low id and lost;
      # now the pushing device is substituted for adjudication as well as for
      # storage, so it wins on merit.
      high_ctx = ctx(workspace_id, user.id, device_id: @high)

      result =
        push_one!(
          high_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "title" => "from high", "updated_at" => at})
          )
        )

      assert result["status"] == "applied"
      assert result["entity"]["title"] == "from high"

      row = Workspace.fetch_live(TimeSpan, workspace_id, id)
      assert row.title == "from high"
      # Stored and adjudicated values agree - one answer to "who authored this".
      assert row.origin_device_id == @high
    end

    test "omitting the field loses when the pushing device genuinely sorts lower", %{
      workspace_id: workspace_id,
      user: user
    } do
      id = uuid7()
      at = @tie_instant

      high_ctx = ctx(workspace_id, user.id, device_id: @high)

      push_one!(
        high_ctx,
        mutation(
          "time_span",
          "create",
          span_payload(%{"id" => id, "title" => "from high", "updated_at" => at})
        )
      )

      low_ctx = ctx(workspace_id, user.id, device_id: @low)

      result =
        push_one!(
          low_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{"id" => id, "title" => "from low", "updated_at" => at})
          )
        )

      # The substitution is not a thumb on the scale: it supplies the true
      # pushing device, which here correctly loses.
      assert result["status"] == "applied"
      assert result["entity"]["title"] == "from high"
      assert result["stale_base"]
    end

    test "sending the field explicitly gives the same answer as omitting it", %{
      workspace_id: workspace_id,
      user: user
    } do
      at = @tie_instant

      outcome = fn send_explicitly? ->
        id = uuid7()
        low_ctx = ctx(workspace_id, user.id, device_id: @low)

        push_one!(
          low_ctx,
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => id,
              "title" => "from low",
              "updated_at" => at,
              "origin_device_id" => @low
            })
          )
        )

        high_ctx = ctx(workspace_id, user.id, device_id: @high)

        payload =
          span_payload(%{"id" => id, "title" => "from high", "updated_at" => at})

        payload =
          if send_explicitly?,
            do: Map.put(payload, "origin_device_id", @high),
            else: payload

        push_one!(high_ctx, mutation("time_span", "update", payload))["entity"]["title"]
      end

      # THE property §8.1 promises: the same two versions produce the same
      # winner regardless of the client's serialization habits. Before the fix
      # these two disagreed, which meant a workspace containing both TimelyKit
      # and Android could not converge.
      assert outcome.(true) == outcome.(false)
      assert outcome.(false) == "from high"
    end

    test "a null origin_device_id is treated as absent, not as a low-sorting value", %{
      workspace_id: workspace_id,
      user: user
    } do
      id = uuid7()
      at = @tie_instant

      low_ctx = ctx(workspace_id, user.id, device_id: @low)

      push_one!(
        low_ctx,
        mutation("time_span", "create", span_payload(%{"id" => id, "updated_at" => at}))
      )

      high_ctx = ctx(workspace_id, user.id, device_id: @high)

      result =
        push_one!(
          high_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => id,
              "title" => "from high",
              "updated_at" => at,
              "origin_device_id" => nil
            })
          )
        )

      # An encoder that emits explicit null for a nil optional must not be
      # penalised differently from one that omits the key.
      assert result["entity"]["title"] == "from high"
    end
  end

  describe "guard_locked requires a current base_revision to unlock" do
    test "an admin with a CURRENT base may clear the lock", %{
      workspace_id: workspace_id,
      user: user
    } do
      span = span!(workspace_id, title: "Approved day", locked_at: DateTime.utc_now())
      admin_ctx = ctx(workspace_id, user.id, admin: true)

      result =
        push_one!(
          admin_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "title" => "Reopened deliberately",
              "locked_at" => nil,
              "updated_at" => "2026-07-28T10:00:00.000000Z"
            }),
            base_revision: span.server_revision
          )
        )

      assert result["status"] == "applied"

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.locked_at == nil
      # Still an auditable event, not a silent edit.
      assert Enum.any?(row.review_reasons, &(&1["code"] == "reopened_after_approval"))
    end

    test "an admin with a STALE base is rejected", %{workspace_id: workspace_id, user: user} do
      span = span!(workspace_id, title: "Approved day", locked_at: DateTime.utc_now())
      admin_ctx = ctx(workspace_id, user.id, admin: true)

      result =
        push_one!(
          admin_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "title" => "Accidentally reopened",
              "locked_at" => nil,
              "updated_at" => "2026-07-28T10:00:00.000000Z"
            }),
            # The admin's copy predates the approval: they are clearing a lock
            # they have never seen.
            base_revision: span.server_revision - 1
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
      assert result["message"] =~ "current base_revision"

      assert Workspace.fetch_live(TimeSpan, workspace_id, span.id).locked_at != nil
    end

    test "an admin with NO base_revision is rejected", %{workspace_id: workspace_id, user: user} do
      span = span!(workspace_id, locked_at: DateTime.utc_now())
      admin_ctx = ctx(workspace_id, user.id, admin: true)

      result =
        push_one!(
          admin_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "locked_at" => nil,
              "updated_at" => "2026-07-28T10:00:00.000000Z"
            })
          )
        )

      # A client that has never seen the row cannot deliberately reopen it.
      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end

    test "a non-admin with a current base is still rejected", %{
      workspace_id: workspace_id,
      user: user
    } do
      span = span!(workspace_id, locked_at: DateTime.utc_now())
      viewer_ctx = ctx(workspace_id, user.id, admin: false)

      result =
        push_one!(
          viewer_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "locked_at" => nil,
              "updated_at" => "2026-07-28T10:00:00.000000Z"
            }),
            base_revision: span.server_revision
          )
        )

      # Freshness is necessary, not sufficient: authority is still required.
      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end

    test "an ordinary edit to a locked span is still rejected regardless of base", %{
      workspace_id: workspace_id,
      user: user
    } do
      span = span!(workspace_id, locked_at: DateTime.utc_now())
      admin_ctx = ctx(workspace_id, user.id, admin: true)

      result =
        push_one!(
          admin_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "title" => "Just editing, not unlocking",
              "updated_at" => "2026-07-28T10:00:00.000000Z"
            }),
            base_revision: span.server_revision
          )
        )

      # The escape hatch is for a DELIBERATE unlock. An edit that does not clear
      # the lock is still an edit to a locked day.
      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end

    test "a policy-range lock also requires a current base to bypass", %{
      workspace_id: workspace_id,
      user: user
    } do
      set_policy!(workspace_id, %{"locked_through" => "2026-07-28T00:00:00.000000Z"})

      span =
        span!(workspace_id,
          title: "Inside a locked range",
          start_at: ~U[2026-07-27 09:00:00.000000Z]
        )

      admin_ctx = ctx(workspace_id, user.id, admin: true)

      result =
        push_one!(
          admin_ctx,
          mutation(
            "time_span",
            "update",
            span_payload(%{
              "id" => span.id,
              "locked_at" => nil,
              "updated_at" => "2026-07-29T10:00:00.000000Z"
            }),
            base_revision: span.server_revision - 1
          )
        )

      assert result["status"] == "rejected"
      assert result["reason"] == "locked_day"
    end
  end
end
