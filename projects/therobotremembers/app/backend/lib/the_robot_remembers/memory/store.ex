defmodule TheRobotRemembers.Memory.Store do
  @moduledoc """
  Synchronous ingest hot path (ADR-010): stamp the emotional vector (agent VAD ++ Monitor
  hormone snapshot — pure arithmetic + a baseline read), run the cheap Guardian gate, and
  store the four texts. The four OpenAI embeddings + Weaviate upsert happen asynchronously
  in `Workers.EmbeddingWorker`.
  """
  require Logger
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.{Memory, Quarantine}
  alias TheRobotRemembers.Memory.{Emotion, Embeddings}
  alias TheRobotRemembers.Agents.{Guardian, Monitor}
  alias TheRobotRemembers.Workers.EmbeddingWorker

  @type context :: %{optional(:owner_agent) => String.t(), optional(:source_agent) => String.t()}

  @spec remember(map(), context()) ::
          {:ok, %{id: Ecto.UUID.t() | nil, status: atom(), confidence: String.t()}} | {:error, term()}
  def remember(attrs, context \\ %{}) do
    attrs = normalize_keys(attrs)
    owner_agent = context[:owner_agent] || attrs[:owner_agent] || "anonymous"

    case Guardian.gate(attrs) do
      {:quarantine, reason} ->
        quarantine(owner_agent, attrs, reason)
        {:ok, %{id: nil, status: :quarantined, confidence: "low"}}

      :ok ->
        do_store(owner_agent, attrs, context)
    end
  end

  @doc "Archive a memory (drops out of recall; reachable later for restore/audit)."
  def archive(memory_id, context \\ %{}), do: set_state(memory_id, context, :archived, prune: true)

  @doc "Restore an archived memory to active."
  def restore(memory_id, context \\ %{}), do: set_state(memory_id, context, :active, prune: false)

  defp set_state(memory_id, context, state, opts) do
    owner = context[:owner_agent]
    pruned_at = if opts[:prune], do: DateTime.utc_now(), else: nil

    query =
      from(m in Memory, where: m.id == ^memory_id)
      |> maybe_owner(owner)

    case Repo.update_all(query, set: [state: state, pruned_at: pruned_at, updated_at: DateTime.utc_now()]) do
      {n, _} when n > 0 -> :ok
      _ -> {:error, :not_found}
    end
  end

  defp maybe_owner(query, nil), do: query
  defp maybe_owner(query, owner), do: where(query, [m], m.owner_agent == ^owner)

  defp do_store(owner_agent, attrs, context) do
    mood = resolve_mood(attrs)
    confidence = if mood, do: "medium", else: "low"
    hormones = Monitor.current_hormones(owner_agent)
    comps = Emotion.components(mood, hormones)
    vector = Emotion.build_vector(mood, hormones)

    now = DateTime.utc_now()
    occurred = parse_dt(attrs[:occurred_at]) || now

    row =
      %{
        owner_agent: owner_agent,
        source_agent: context[:source_agent] || attrs[:source_agent] || "external",
        organization_id: attrs[:organization_id],
        project_id: attrs[:project_id],
        content: attrs[:content],
        context: attrs[:context],
        reflection: attrs[:reflection],
        tangent: attrs[:tangent],
        summary: attrs[:summary],
        content_type: attrs[:content_type] || :episodic,
        emotional_embedding: vector,
        confidence: confidence,
        occurred_at: occurred,
        time_of_day: time_of_day(occurred),
        day_of_week: Date.day_of_week(DateTime.to_date(occurred)),
        season: season(occurred),
        domain: attrs[:domain],
        topic: attrs[:topic],
        session_id: attrs[:session_id],
        modality: attrs[:modality],
        collaborators: attrs[:collaborators] || [],
        environment: attrs[:environment] || %{},
        compartment: attrs[:compartment] || "default",
        classification: attrs[:classification] || :open,
        state: :consolidating,
        last_reinforced_at: now
      }
      |> Map.merge(comps)

    case %Memory{} |> Memory.changeset(row) |> Repo.insert() do
      {:ok, mem} ->
        enqueue_embedding(mem.id)
        status = if Embeddings.configured?(), do: :embedding_pending, else: :stored
        {:ok, %{id: mem.id, status: status, confidence: confidence}}

      {:error, changeset} ->
        Logger.warning("[Store] insert failed: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  # Accept mood either as a nested `:mood` map or flat valence/arousal/dominance keys.
  defp resolve_mood(attrs) do
    case attrs[:mood] do
      m when is_map(m) ->
        m

      _ ->
        flat = Map.take(attrs, [:valence, :arousal, :dominance])
        if map_size(flat) > 0, do: flat, else: nil
    end
  end

  defp enqueue_embedding(memory_id) do
    %{memory_id: memory_id} |> EmbeddingWorker.new() |> Oban.insert()
    :ok
  rescue
    e -> Logger.warning("[Store] could not enqueue embedding: #{inspect(e)}"); :ok
  catch
    :exit, reason -> Logger.warning("[Store] embedding enqueue exit: #{inspect(reason)}"); :ok
  end

  defp quarantine(owner_agent, attrs, reason) do
    %Quarantine{}
    |> Quarantine.changeset(%{
      owner_agent: owner_agent,
      reason: reason,
      payload: %{"content" => attrs[:content], "domain" => attrs[:domain]}
    })
    |> Repo.insert()
  end

  # ── enrichment helpers (Archivist fast-enrich) ──────────────────
  defp time_of_day(%DateTime{hour: h}) do
    cond do
      h < 6 -> "night"
      h < 12 -> "morning"
      h < 18 -> "afternoon"
      true -> "evening"
    end
  end

  defp season(%DateTime{month: m}) do
    cond do
      m in [12, 1, 2] -> "winter"
      m in [3, 4, 5] -> "spring"
      m in [6, 7, 8] -> "summer"
      true -> "autumn"
    end
  end

  defp parse_dt(%DateTime{} = dt), do: dt
  defp parse_dt(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_dt(_), do: nil

  defp normalize_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {k, v} when is_binary(k) -> {safe_atom(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp safe_atom(k) do
    String.to_existing_atom(k)
  rescue
    ArgumentError -> k
  end
end
