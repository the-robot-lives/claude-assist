defmodule Timely.Sync.Revisions do
  @moduledoc """
  Allocation of `server_revision`, the one and only sync cursor.

  ## Why a counter row and not a sequence

  A Postgres `SEQUENCE` is the obvious choice and it is wrong here, twice over:

  - **It is non-transactional.** `nextval` does not roll back, so an aborted
    push leaves a permanent gap. A puller that stops at the highest committed
    revision would then park forever behind a number that will never exist, and
    one that does not stop there re-reads rows or skips them.
  - **A single global sequence leaks tenancy.** Revision numbers would expose
    cross-workspace write volume, and a quiet workspace sitting behind a noisy
    one would carry a watermark that jumps by thousands between its own writes.

  So the counter is a row in `timely_workspace_revisions`, one per workspace.

  ## Why this is race-free

  `allocate!/1` issues

      UPDATE timely_workspace_revisions
         SET current_revision = current_revision + 1
       WHERE workspace_id = $1
      RETURNING current_revision

  which takes a **row-level exclusive lock that Postgres holds until the
  transaction commits or aborts**. Three properties follow, and together they
  are exactly what SYNC-PROTOCOL section 5 demands:

  1. **Allocation order equals commit order.** A second pusher for the same
     workspace blocks on the lock until the first one finishes, so it cannot
     receive a revision *number* before the first pusher's *rows* are committed.
     There is never a committed revision 102 while 101 is still in flight.
  2. **The sequence is gap-free.** An aborted transaction rolls the counter back
     with everything else.
  3. **A plain read is a safe watermark.** Under MVCC a reader sees the last
     committed `current_revision`, never an in-flight one, and by (1) every
     revision at or below it is committed. So `committed_watermark/1` is the
     "highest gap-free committed revision" the pull endpoint must not advance
     past - no `pg_snapshot_xmin` inspection and no watermark-lag window needed.

  The naive alternative - `SELECT max(server_revision)` then insert that plus
  one - is a lost-update race: two concurrent pushers read the same max and both
  write the same revision, so one of the two rows is invisible to every client
  whose cursor steps past it. That failure is silent and permanent, which is why
  allocation is centralised here and `allocate!/1` refuses to run outside a
  transaction.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Sync.WorkspaceRevision

  @doc """
  Allocates the next `server_revision` for a workspace.

  MUST be called inside the transaction that publishes the row - that is the
  whole mechanism. Raises otherwise rather than silently allocating a revision
  that commits at some unrelated moment.
  """
  # ⟦𓂋𓆓𓈖𓋴⟧ allocate! :: Allocates the next server_revision for a workspace.
  def allocate!(workspace_id) do
    unless Repo.in_transaction?() do
      raise ArgumentError, """
      Timely.Sync.Revisions.allocate!/1 was called outside a transaction.

      The revision must be allocated in the same transaction that publishes the
      row, otherwise revision order stops matching commit order and pullers
      silently lose rows.
      """
    end

    ensure_counter!(workspace_id)

    %{rows: [[revision]]} =
      Repo.query!(
        """
        UPDATE timely_workspace_revisions
           SET current_revision = current_revision + 1,
               updated_at = now()
         WHERE workspace_id = $1
        RETURNING current_revision
        """,
        [uuid!(workspace_id)]
      )

    revision
  end

  @doc """
  The highest revision that is committed and gap-free - the ceiling a pull page
  must not advance past. See the module doc for why a plain read is sufficient.
  """
  # ⟦𓅱𓏏𓂋𓅓⟧ committed_watermark :: Highest gap-free committed revision.
  def committed_watermark(workspace_id) do
    WorkspaceRevision
    |> where([r], r.workspace_id == ^workspace_id)
    |> select([r], r.current_revision)
    |> Repo.one()
    |> Kernel.||(0)
  end

  @doc """
  The oldest revision for which tombstones are still guaranteed present. A client
  whose cursor is below this must re-bootstrap from 0 (`410 cursor_too_old`).
  """
  # ⟦𓏏𓅓𓃀𓎛⟧ tombstone_horizon :: Oldest revision with guaranteed tombstones.
  def tombstone_horizon(workspace_id) do
    WorkspaceRevision
    |> where([r], r.workspace_id == ^workspace_id)
    |> select([r], r.tombstone_horizon_revision)
    |> Repo.one()
    |> Kernel.||(0)
  end

  @doc """
  Creates the counter row for a workspace if it does not exist yet. Idempotent
  and safe to race - two concurrent callers both end up with exactly one row.
  """
  # ⟦𓎛𓋴𓂋𓈖⟧ ensure_counter! :: Creates the per-workspace counter row if absent.
  def ensure_counter!(workspace_id) do
    Repo.query!(
      """
      INSERT INTO timely_workspace_revisions (workspace_id, current_revision, tombstone_horizon_revision)
      VALUES ($1, 0, 0)
      ON CONFLICT (workspace_id) DO NOTHING
      """,
      [uuid!(workspace_id)]
    )

    :ok
  end

  defp uuid!(value) do
    {:ok, dumped} = Ecto.UUID.dump(value)
    dumped
  end
end
