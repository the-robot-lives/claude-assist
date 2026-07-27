defmodule Timely.Sync.RevisionsTest do
  @moduledoc """
  The `server_revision` allocator (SYNC-PROTOCOL section 5).

  The concurrency tests deliberately bypass the Ecto sandbox and open their own
  Postgrex connections. Under the sandbox every process shares one connection
  inside one never-committed transaction, so two "concurrent" allocations would
  be serialised by the test harness rather than by the row lock - and the test
  would pass for a reason that has nothing to do with the code under test. Real
  connections and real commits are the only way to demonstrate the property.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Sync.Revisions

  describe "allocate!/1" do
    test "refuses to run outside a transaction" do
      workspace_id = workspace!()

      # Allocating outside the publishing transaction would decouple revision
      # order from commit order, which is the exact failure the cursor design
      # exists to prevent - so it raises rather than quietly working.
      assert_raise ArgumentError, ~r/outside a transaction/, fn ->
        Revisions.allocate!(workspace_id)
      end
    end

    test "is monotonic within a workspace" do
      workspace_id = workspace!()

      {:ok, revisions} =
        Repo.transaction(fn -> for _ <- 1..5, do: Revisions.allocate!(workspace_id) end)

      assert revisions == Enum.sort(revisions)
      assert revisions == Enum.uniq(revisions)
      assert List.last(revisions) - List.first(revisions) == 4
    end

    test "counts per workspace, so a quiet tenant does not inherit a noisy one's numbers" do
      quiet = workspace!()
      noisy = workspace!()

      {:ok, _} = Repo.transaction(fn -> for _ <- 1..50, do: Revisions.allocate!(noisy) end)
      {:ok, [first]} = Repo.transaction(fn -> [Revisions.allocate!(quiet)] end)

      # A shared global sequence would leak the noisy workspace's write volume
      # and would make the quiet workspace's watermark jump by 50.
      assert first == 1
    end

    test "ensure_counter!/1 is idempotent and safe to race" do
      workspace_id = workspace!()

      for _ <- 1..5, do: Revisions.ensure_counter!(workspace_id)

      assert Repo.aggregate(
               Timely.Schema.Sync.WorkspaceRevision
               |> Ecto.Query.where(workspace_id: ^workspace_id),
               :count
             ) == 1
    end
  end

  describe "committed_watermark/1" do
    test "starts at zero for a fresh workspace" do
      assert Revisions.committed_watermark(workspace!()) == 0
    end

    test "tracks the highest allocated revision" do
      workspace_id = workspace!()
      {:ok, _} = Repo.transaction(fn -> for _ <- 1..3, do: Revisions.allocate!(workspace_id) end)

      assert Revisions.committed_watermark(workspace_id) == 3
    end
  end

  describe "concurrency (real connections, real commits)" do
    @describetag :concurrency

    setup do
      config = Application.fetch_env!(:timely, Timely.Repo)

      opts = [
        hostname: Keyword.get(config, :hostname, "localhost"),
        port: Keyword.get(config, :port, 5432),
        username: Keyword.fetch!(config, :username),
        password: Keyword.get(config, :password, ""),
        database: Keyword.fetch!(config, :database),
        pool_size: 1
      ]

      # One committed workspace outside the sandbox, torn down explicitly.
      {:ok, admin} = Postgrex.start_link(opts)
      workspace_id = Ecto.UUID.generate()
      slug = "concurrency-#{System.unique_integer([:positive])}"

      Postgrex.query!(
        admin,
        "INSERT INTO organizations (id, slug, name, settings, inserted_at, updated_at) VALUES ($1, $2, $3, '{}'::jsonb, now(), now())",
        [Ecto.UUID.dump!(workspace_id), slug, "Concurrency Test"]
      )

      Postgrex.query!(
        admin,
        "INSERT INTO timely_workspace_revisions (workspace_id) VALUES ($1)",
        [Ecto.UUID.dump!(workspace_id)]
      )

      on_exit(fn ->
        {:ok, cleanup} = Postgrex.start_link(opts)

        Postgrex.query!(cleanup, "DELETE FROM organizations WHERE id = $1", [
          Ecto.UUID.dump!(workspace_id)
        ])

        GenServer.stop(cleanup)
      end)

      {:ok, workspace_id: workspace_id, opts: opts, admin: admin}
    end

    test "concurrent pushers never receive the same revision and leave no gaps", %{
      workspace_id: workspace_id,
      opts: opts
    } do
      writers = 8
      per_writer = 5

      results =
        1..writers
        |> Task.async_stream(
          fn _ ->
            {:ok, conn} = Postgrex.start_link(opts)

            {:ok, allocated} =
              Postgrex.transaction(
                conn,
                fn tx ->
                  Enum.map(1..per_writer, fn _ ->
                    %{rows: [[revision]]} =
                      Postgrex.query!(
                        tx,
                        """
                        UPDATE timely_workspace_revisions
                           SET current_revision = current_revision + 1
                         WHERE workspace_id = $1
                        RETURNING current_revision
                        """,
                        [Ecto.UUID.dump!(workspace_id)]
                      )

                    # Widen the window in which an interleave could happen. A
                    # naive read-max-then-increment fails here every time.
                    Process.sleep(5)
                    revision
                  end)
                end,
                timeout: 30_000
              )

            GenServer.stop(conn)
            allocated
          end,
          max_concurrency: writers,
          timeout: 60_000
        )
        |> Enum.map(fn {:ok, allocated} -> allocated end)

      all = results |> List.flatten() |> Enum.sort()
      total = writers * per_writer

      # No lost update: every allocation is distinct.
      assert length(Enum.uniq(all)) == total

      # Gap-free: the allocations are exactly 1..N with nothing missing, which is
      # what lets a puller stop at the highest committed revision and resume
      # from it without ever parking behind a number that will never exist.
      assert all == Enum.to_list(1..total)

      # And the lock is held for the whole transaction, not just the statement:
      # each writer's own allocations are contiguous, so no other writer slipped
      # a number in between. This is the property that makes allocation order
      # equal commit order.
      for allocated <- results do
        assert allocated == Enum.sort(allocated)
        assert List.last(allocated) - List.first(allocated) == per_writer - 1
      end
    end

    test "an aborted transaction rolls the counter back, leaving no gap", %{
      workspace_id: workspace_id,
      opts: opts,
      admin: admin
    } do
      {:ok, conn} = Postgrex.start_link(opts)

      {:error, :deliberate} =
        Postgrex.transaction(conn, fn tx ->
          Postgrex.query!(
            tx,
            "UPDATE timely_workspace_revisions SET current_revision = current_revision + 1 WHERE workspace_id = $1 RETURNING current_revision",
            [Ecto.UUID.dump!(workspace_id)]
          )

          Postgrex.rollback(tx, :deliberate)
        end)

      GenServer.stop(conn)

      %{rows: [[current]]} =
        Postgrex.query!(
          admin,
          "SELECT current_revision FROM timely_workspace_revisions WHERE workspace_id = $1",
          [Ecto.UUID.dump!(workspace_id)]
        )

      # A Postgres SEQUENCE would have left this at 1: nextval does not roll
      # back. That permanent gap is why the counter is a row.
      assert current == 0
    end

    test "a reader never observes an in-flight allocation", %{
      workspace_id: workspace_id,
      opts: opts,
      admin: admin
    } do
      {:ok, writer} = Postgrex.start_link(opts)
      test_pid = self()

      task =
        Task.async(fn ->
          Postgrex.transaction(
            writer,
            fn tx ->
              Postgrex.query!(
                tx,
                "UPDATE timely_workspace_revisions SET current_revision = current_revision + 1 WHERE workspace_id = $1 RETURNING current_revision",
                [Ecto.UUID.dump!(workspace_id)]
              )

              send(test_pid, :allocated)
              # Hold the transaction open, uncommitted.
              receive do: (:release -> :ok)
            end,
            timeout: 30_000
          )
        end)

      assert_receive :allocated, 5_000

      %{rows: [[visible]]} =
        Postgrex.query!(
          admin,
          "SELECT current_revision FROM timely_workspace_revisions WHERE workspace_id = $1",
          [Ecto.UUID.dump!(workspace_id)]
        )

      # Under MVCC the reader sees the last committed value, so the watermark it
      # would publish covers only rows that are already committed. This is why
      # `committed_watermark/1` needs no snapshot inspection or lag window.
      assert visible == 0

      send(task.pid, :release)
      Task.await(task, 30_000)
      GenServer.stop(writer)
    end
  end
end
