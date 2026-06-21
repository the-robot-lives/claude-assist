defmodule TheRobotRemembers.Workers.EmbeddingWorker do
  @moduledoc """
  Async tail of ingest (ADR-010): embed the present text facets (content/context/reflection/
  tangent) with OpenAI and upsert them to Weaviate as named vectors, then flip the memory to
  `active`. If embeddings/Weaviate aren't configured, the memory is still activated so
  emotional-resonance recall works — only semantic/text recall is unavailable until vectors land.
  """
  use Oban.Worker, queue: :memory, max_attempts: 3
  require Logger

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.Memory
  alias TheRobotRemembers.Memory.{Embeddings, VectorStore}
  alias TheRobotRemembers.Workers.LinkJob

  @facets ~w(content context reflection tangent)a

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"memory_id" => id}}) do
    case Repo.get(Memory, id) do
      nil ->
        :ok

      mem ->
        texts = for f <- @facets, t = Map.get(mem, f), is_binary(t) and String.trim(t) != "", do: {f, t}

        if Embeddings.configured?() and VectorStore.configured?() and texts != [] do
          embed_and_sync(mem, texts)
        else
          activate(mem, synced: false, model: nil)
        end

        # Hand off to the Weaver now that vectors (if any) have landed.
        enqueue_link(id)
        :ok
    end
  end

  defp enqueue_link(memory_id) do
    %{memory_id: memory_id} |> LinkJob.new() |> Oban.insert()
    :ok
  rescue
    e -> require Logger; Logger.warning("[EmbeddingWorker] could not enqueue link: #{inspect(e)}"); :ok
  catch
    :exit, _ -> :ok
  end

  defp embed_and_sync(mem, texts) do
    {names, values} = Enum.unzip(texts)

    case Embeddings.embed(values) do
      {:ok, vectors} ->
        named = names |> Enum.map(&Atom.to_string/1) |> Enum.zip(vectors) |> Map.new()
        VectorStore.ensure_class()

        props = %{
          "owner_agent" => mem.owner_agent,
          "compartment" => mem.compartment,
          "classification" => to_string(mem.classification),
          "content_type" => to_string(mem.content_type)
        }

        case VectorStore.upsert(mem.id, named, props) do
          :ok -> activate(mem, synced: true, model: Embeddings.model())
          other ->
            Logger.warning("[EmbeddingWorker] weaviate upsert failed for #{mem.id}: #{inspect(other)}")
            activate(mem, synced: false, model: Embeddings.model())
        end

      {:error, reason} ->
        Logger.warning("[EmbeddingWorker] embed failed for #{mem.id}: #{inspect(reason)}")
        activate(mem, synced: false, model: nil)
    end
  end

  defp activate(mem, opts) do
    mem
    |> Ecto.Changeset.change(%{
      state: :active,
      vectors_synced: Keyword.get(opts, :synced, false),
      embedding_model: Keyword.get(opts, :model)
    })
    |> Repo.update()

    :ok
  end
end
