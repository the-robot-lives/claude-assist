defmodule Therobotknows.Workers.GenerationWorker do
  use Oban.Worker, queue: :default, max_attempts: 2

  alias Therobotknows.Repo
  alias Therobotknows.Generations
  alias Therobotknows.Schema.Generation.Generation

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"generation_id" => id}}) do
    case Repo.get(Generation, id) do
      nil -> :ok
      %Generation{status: status} when status in ["complete", "promoted", "discarded"] -> :ok
      gen -> Generations.run_generation(gen)
    end

    :ok
  end
end
