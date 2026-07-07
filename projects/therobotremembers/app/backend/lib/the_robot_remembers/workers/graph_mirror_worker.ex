defmodule TheRobotRemembers.Workers.GraphMirrorWorker do
  @moduledoc """
  Async projection of the association graph into Apache AGE (Phase A). Same queue/attempt
  conventions as `EmbeddingWorker`. Every op no-ops when the AGE layer is disabled
  (`GraphMirror.enabled?/0`), so enqueuing is always safe — when the flag is off the enqueue
  helpers skip Oban entirely and this worker never runs.

  Ops (`args["op"]`):
    * `"sync"`      — re-project the neighborhood of `memory_ids` (upsert/remove edges + vertices).
    * `"vertex"`    — upsert a single memory's vertex.
    * `"reconcile"` — drop AGE vertices whose `memories` row no longer exists (PG cascade catch-up).
    * `"backfill"`  — rebuild the whole projection from Postgres.
  """
  use Oban.Worker, queue: :memory, max_attempts: 3

  alias TheRobotRemembers.Memory.GraphMirror

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"op" => "sync", "memory_ids" => ids}}) when is_list(ids) do
    GraphMirror.sync_memories(ids)
    :ok
  end

  def perform(%Oban.Job{args: %{"op" => "vertex", "memory_id" => id}}) when is_binary(id) do
    GraphMirror.upsert_memory_vertex(id)
    :ok
  end

  def perform(%Oban.Job{args: %{"op" => "reconcile"}}) do
    GraphMirror.reconcile()
    :ok
  end

  def perform(%Oban.Job{args: %{"op" => "backfill"}}) do
    GraphMirror.backfill()
    :ok
  end

  def perform(_), do: :ok
end
