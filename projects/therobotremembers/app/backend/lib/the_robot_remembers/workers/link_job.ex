defmodule TheRobotRemembers.Workers.LinkJob do
  @moduledoc """
  Runs the Weaver for a memory after its embeddings land — creates the association edges
  (emotional/temporal/contextual always; tangent/semantic when Weaviate is enabled).
  """
  use Oban.Worker, queue: :memory, max_attempts: 3, unique: [keys: [:memory_id], period: 120]

  alias TheRobotRemembers.Agents.Weaver

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"memory_id" => id}}) do
    Weaver.link(id)
    :ok
  end
end
