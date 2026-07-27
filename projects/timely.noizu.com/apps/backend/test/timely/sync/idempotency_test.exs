defmodule Timely.Sync.IdempotencyTest do
  @moduledoc """
  SYNC-PROTOCOL section 9: the mutation ledger and client-generated ids as the
  backstop past its retention window.

  The push queue is at-least-once, so duplicate delivery is expected rather than
  exceptional, and both suppression mechanisms have to hold.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Sync.AppliedMutation
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Mutations
  alias Timely.Sync.Workspace

  setup do
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     ctx: ctx(workspace_id, user.id, device_id: device.id)}
  end

  defp span_payload(overrides) do
    Map.merge(
      %{
        "id" => uuid7(),
        "title" => "Timeline canvas",
        "start" => iso(-3600),
        "end" => iso(-60),
        "source" => "timer",
        "is_billable" => false,
        "updated_at" => iso(-60)
      },
      overrides
    )
  end

  describe "the mutation ledger" do
    test "a replayed mutation_id returns the original result verbatim", %{ctx: ctx} do
      mutation_id = uuid7()
      id = uuid7()

      m = mutation("time_span", "create", span_payload(%{"id" => id}), mutation_id: mutation_id)

      {:ok, [first]} = Mutations.push(ctx, [m])
      {:ok, [second]} = Mutations.push(ctx, [m])

      assert first["replayed"] == false
      assert second["replayed"] == true

      # Everything but `replayed` is the original answer, byte for byte.
      assert Map.delete(second, "replayed") == Map.delete(first, "replayed")
    end

    test "a replay does not re-apply, does not bump server_revision", %{ctx: ctx} do
      mutation_id = uuid7()
      id = uuid7()

      m = mutation("time_span", "create", span_payload(%{"id" => id}), mutation_id: mutation_id)

      {:ok, [first]} = Mutations.push(ctx, [m])
      revision_after_first = Workspace.fetch_live(TimeSpan, ctx.workspace_id, id).server_revision

      {:ok, [second]} = Mutations.push(ctx, [m])
      revision_after_second = Workspace.fetch_live(TimeSpan, ctx.workspace_id, id).server_revision

      assert revision_after_first == revision_after_second
      assert second["entity"]["server_revision"] == first["entity"]["server_revision"]
    end

    test "a replay does not re-run duplicate detection", %{ctx: ctx, workspace_id: workspace_id} do
      start = DateTime.utc_now() |> DateTime.add(-3600, :second)
      neighbour = span!(workspace_id, title: "Same work", start_at: start, end_at: DateTime.add(start, 600, :second))

      mutation_id = uuid7()
      id = uuid7()

      m =
        mutation(
          "time_span",
          "create",
          span_payload(%{
            "id" => id,
            "title" => "Same work",
            "start" => DateTime.to_iso8601(start),
            "end" => DateTime.to_iso8601(DateTime.add(start, 600, :second))
          }),
          mutation_id: mutation_id
        )

      {:ok, _} = Mutations.push(ctx, [m])
      flags_after_first = flag_count(workspace_id, neighbour.id)

      {:ok, _} = Mutations.push(ctx, [m])
      flags_after_replay = flag_count(workspace_id, neighbour.id)

      assert flags_after_replay == flags_after_first
    end

    test "rejected results are recorded so a retry gets the same terminal answer", %{ctx: ctx} do
      mutation_id = uuid7()
      m = mutation("wormhole", "create", %{"id" => uuid7()}, mutation_id: mutation_id)

      {:ok, [first]} = Mutations.push(ctx, [m])
      {:ok, [second]} = Mutations.push(ctx, [m])

      assert first["status"] == "rejected"
      assert second["status"] == "rejected"
      assert second["replayed"] == true
    end

    test "the ledger is workspace-scoped, so one workspace cannot answer another's replay", %{
      ctx: ctx,
      user: user
    } do
      other_workspace = workspace!()
      member!(user.id, other_workspace, "owner")
      other_ctx = ctx(other_workspace, user.id)

      mutation_id = uuid7()

      first_m =
        mutation("time_span", "create", span_payload(%{"id" => uuid7()}),
          mutation_id: mutation_id
        )

      # A distinct row id, because ids are globally unique - reusing one across
      # workspaces is its own error, covered below.
      second_m =
        mutation("time_span", "create", span_payload(%{"id" => uuid7()}),
          mutation_id: mutation_id
        )

      {:ok, [first]} = Mutations.push(ctx, [first_m])
      assert first["status"] == "applied"

      # Same mutation_id, different workspace: the ledger lookup is keyed on
      # both, so this is a fresh mutation rather than a replay.
      {:ok, [second]} = Mutations.push(other_ctx, [second_m])
      assert second["replayed"] == false
      assert second["status"] == "applied"
    end

    test "an id that already exists in another workspace is rejected, not raised", %{
      ctx: ctx,
      user: user
    } do
      other_workspace = workspace!()
      member!(user.id, other_workspace, "owner")
      other_ctx = ctx(other_workspace, user.id)

      id = uuid7()

      {:ok, [first]} =
        Mutations.push(ctx, [mutation("time_span", "create", span_payload(%{"id" => id}))])

      assert first["status"] == "applied"

      # The row is invisible to the other workspace's scoped lookup, so this
      # reaches the insert as a create. It must answer with a terminal result
      # rather than a raised constraint error - which would be a 500, and a
      # probe for whether an id exists elsewhere.
      {:ok, [second]} =
        Mutations.push(other_ctx, [mutation("time_span", "create", span_payload(%{"id" => id}))])

      assert second["status"] == "rejected"
      assert second["reason"] == "workspace_mismatch"
    end

    test "an atomic rollback also unwinds its ledger entries, so a retry re-applies", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      locked = span!(workspace_id, locked_at: DateTime.utc_now())
      good_id = uuid7()
      good_mutation_id = uuid7()

      atomic_ctx = Map.put(ctx, :atomic, true)

      batch = [
        mutation("time_span", "create", span_payload(%{"id" => good_id}),
          mutation_id: good_mutation_id
        ),
        mutation(
          "time_span",
          "update",
          span_payload(%{"id" => locked.id, "updated_at" => iso()})
        )
      ]

      {:conflict, _} = Mutations.push(atomic_ctx, batch)

      # If the ledger entry had survived the rollback, the retry would be
      # answered as a replay of a mutation that never actually wrote anything -
      # a permanently lost write.
      refute Repo.exists?(
               AppliedMutation |> Ecto.Query.where(mutation_id: ^good_mutation_id)
             )

      {:ok, [result]} =
        Mutations.push(ctx, [
          mutation("time_span", "create", span_payload(%{"id" => good_id}),
            mutation_id: good_mutation_id
          )
        ])

      assert result["status"] == "applied"
      assert result["replayed"] == false
      assert Workspace.fetch_live(TimeSpan, workspace_id, good_id) != nil
    end
  end

  describe "client-generated ids as the backstop" do
    test "a replay past the ledger window converges on one row", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      id = uuid7()

      {:ok, _} =
        Mutations.push(ctx, [
          mutation("time_span", "create", span_payload(%{"id" => id}), mutation_id: uuid7())
        ])

      # Simulate the ledger having been pruned: same payload, fresh mutation_id.
      Repo.delete_all(AppliedMutation)

      {:ok, [result]} =
        Mutations.push(ctx, [
          mutation("time_span", "create", span_payload(%{"id" => id, "updated_at" => iso()}),
            mutation_id: uuid7()
          )
        ])

      assert result["status"] == "applied"
      assert result["replayed"] == false

      # Rule 4: the create degraded to an update rather than producing a second
      # row. This is why locally minted primary keys are a correctness property.
      assert Repo.aggregate(
               TimeSpan |> Workspace.scope(workspace_id) |> Ecto.Query.where(id: ^id),
               :count
             ) == 1
    end
  end

  defp flag_count(workspace_id, span_id) do
    Workspace.fetch_live(TimeSpan, workspace_id, span_id).review_reasons
    |> Kernel.||([])
    |> length()
  end
end
