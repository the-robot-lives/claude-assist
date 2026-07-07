defmodule TheRobotRemembers.Memory.Console do
  @moduledoc """
  Shared internal API backing the memory UI/console — the single surface both the HTTP controllers
  (`TheRobotRemembersWeb.MemoryController`) and the MCP ops tools delegate to (API contract Phase D).

  Every read is tenant-scoped to the requested `agent_id` (= `owner_agent`) and classification-gated
  by the same rules recall uses. In particular the graph endpoints only ever return edges whose
  **both** endpoints are memories owned by `agent_id` — association edges can cross owners (a
  no-owner recall's Hebbian co_occurrence edges), so an owner filter on a single endpoint is not
  enough. Mutations verify ownership before writing and flow weight changes into the AGE projection
  via `GraphMirror` (no-op when the graph layer is disabled).
  """
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge, AgentState, Compartment}
  alias TheRobotRemembers.Memory.{Recall, Reinforcement, Store, GraphMirror, Emotion, GraphStore}

  # ── agents ──────────────────────────────────────────────────────
  @doc "List agents that have memory state, with memory + edge counts and the current mood bucket."
  def agents do
    mem_counts =
      Repo.all(from(m in Memory, group_by: m.owner_agent, select: {m.owner_agent, count(m.id)}))
      |> Map.new()

    edge_counts =
      Repo.all(
        from(e in AssociationEdge,
          join: m in Memory,
          on: m.id == e.source_memory_id,
          group_by: m.owner_agent,
          select: {m.owner_agent, count(e.id)}
        )
      )
      |> Map.new()

    states = Repo.all(from(s in AgentState, select: {s.agent_id, s.current_bucket})) |> Map.new()

    (Map.keys(mem_counts) ++ Map.keys(states))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn a ->
      %{
        agent_id: a,
        # Non-null per the frontend MemoryAgent type; no stored bucket yet (Monitor is a Phase-0 stub).
        current_bucket: Map.get(states, a) || "neutral",
        memory_count: Map.get(mem_counts, a, 0),
        edge_count: Map.get(edge_counts, a, 0)
      }
    end)
  end

  # ── graph / subgraph ────────────────────────────────────────────
  @doc """
  Return the agent's memory subgraph. Without `:seed` the whole ≥`min_weight` graph (node-capped by
  `:limit`, strongest salience first); with `:seed` the ≤`hops` traversal neighborhood of that
  memory. Nodes are always owner-scoped; edges only appear when both endpoints are in the node set.
  """
  def subgraph(agent_id, opts \\ []) do
    min_weight = opt_float(opts[:min_weight], 0.2)
    limit = opt_int(opts[:limit], 500)
    compartment = opts[:compartment]

    # Seed narrows the fetch to a neighborhood (adapter-specific traversal); no seed = whole graph.
    candidate_ids =
      case opts[:seed] do
        s when is_binary(s) and s != "" ->
          hops = opts[:hops] |> opt_int(2) |> clamp_int(1, 3)

          case cast_uuid(s) do
            {:ok, seed} ->
              case GraphStore.neighborhood(seed, hops, min_weight: min_weight) do
                {:ok, ids} -> ids
                _ -> []
              end

            :error ->
              []
          end

        _ ->
          :all
      end

    # The owner-scoped node/edge fetch runs through the GraphStore seam (both endpoints owner-scoped,
    # so cross-owner ids from a neighborhood traversal never surface). Serialize to the contract shape.
    case GraphStore.subgraph(agent_id,
           compartment: compartment,
           min_weight: min_weight,
           limit: limit,
           candidate_ids: candidate_ids
         ) do
      {:ok, %{nodes: nodes, edges: edges, truncated: truncated}} ->
        %{nodes: Enum.map(nodes, &node_view/1), edges: Enum.map(edges, &edge_view/1), truncated: truncated}

      _ ->
        %{nodes: [], edges: [], truncated: false}
    end
  end

  # ── recall preview (side-effect-free) ───────────────────────────
  @doc "Preview recall for an agent (no reinforcement) with the per-result RRF contribution breakdown."
  def recall_preview(agent_id, params, context \\ %{}) do
    ctx = Map.merge(%{owner_agent: agent_id, requester_id: agent_id}, context)
    query = params[:query] || params["query"]

    opts =
      [
        limit: opt_int(params[:limit] || params["limit"], nil),
        mood: params[:mood] || params["mood"],
        overrides: params[:overrides] || params["overrides"]
      ]
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    {:ok, %{results: results, duration_ms: ms}} = Recall.preview(query, opts, ctx)

    {:ok,
     %{
       results:
         Enum.map(results, fn r ->
           %{
             memory: node_view(r.memory),
             score: round6(r.score),
             contributions:
               Enum.map(r.contributions, fn c ->
                 %{source: c.source, rank: c.rank, score: round6(c.score)}
               end)
           }
         end),
       duration_ms: ms
     }}
  end

  # ── edge / memory mutations ─────────────────────────────────────
  @doc "Set an edge's weight (clamped [0,1]) with provenance, tenant-checked; syncs to AGE."
  def set_edge_weight(agent_id, edge_id, weight, meta \\ %{}) do
    with {:ok, edge} <- fetch_owned_edge(agent_id, edge_id),
         {:ok, updated} <-
           edge
           |> Ecto.Changeset.change(%{
             weight: clampf(to_f(weight), 0.0, 1.0),
             created_by: meta[:created_by] || "user",
             reason: meta[:reason],
             updated_at: DateTime.utc_now()
           })
           |> Repo.update() do
      # Flows to AGE (upsert, or removal when < min_weight) — no-op if the graph layer is off.
      GraphMirror.enqueue_sync([updated.source_memory_id, updated.target_memory_id])
      {:ok, edge_view(updated)}
    end
  end

  @doc "Set decay_weight (clamped [0.05,1.0]) and/or pinned on a memory, tenant-checked."
  def set_memory(agent_id, memory_id, attrs) do
    a = normalize_attrs(attrs, [:decay_weight, :pinned])

    with {:ok, mem} <- fetch_owned_memory(agent_id, memory_id) do
      changes =
        %{}
        |> maybe_change(a, :decay_weight, fn v -> clampf(to_f(v), 0.05, 1.0) end)
        |> maybe_change(a, :pinned, &truthy/1)

      if changes == %{} do
        {:error, :no_changes}
      else
        case mem |> Ecto.Changeset.change(Map.put(changes, :updated_at, DateTime.utc_now())) |> Repo.update() do
          {:ok, updated} -> {:ok, node_view(updated)}
          {:error, changeset} -> {:error, changeset}
        end
      end
    end
  end

  @doc "Standard-step Hebbian reinforce of a memory (delegates to Reinforcement), tenant-checked."
  def reinforce(agent_id, memory_id), do: nudge(agent_id, memory_id, &Reinforcement.reinforce/2)
  @doc "Standard-step denforce of a memory, tenant-checked."
  def denforce(agent_id, memory_id), do: nudge(agent_id, memory_id, &Reinforcement.denforce/2)

  @doc "Archive a memory (drops it from recall), tenant-checked."
  def archive(agent_id, memory_id), do: set_state(agent_id, memory_id, &Store.archive/2)
  @doc "Restore an archived memory, tenant-checked."
  def restore(agent_id, memory_id), do: set_state(agent_id, memory_id, &Store.restore/2)

  # ── agent mood (memory_agent_state) ─────────────────────────────
  @doc "Read the agent's current emotional state (stored, or the Monitor-stub default)."
  def mood_get(agent_id) do
    case Repo.get(AgentState, agent_id) do
      %AgentState{} = s ->
        %{
          agent_id: agent_id,
          status: s.status,
          current_bucket: s.current_bucket,
          mood: s.metrics["mood"] || Emotion.neutral_mood(),
          hormones: s.metrics["hormones"] || Emotion.hormone_baseline(),
          source: "stored"
        }

      nil ->
        %{
          agent_id: agent_id,
          status: "active",
          current_bucket: nil,
          mood: Emotion.neutral_mood(),
          hormones: Emotion.hormone_baseline(),
          source: "default"
        }
    end
  end

  @doc "Write the agent's current emotional state (VAD mood + hormones) into memory_agent_state."
  def mood_set(agent_id, params) do
    mood = stringify_nums(params[:mood] || params["mood"] || %{})
    hormones = stringify_nums(params[:hormones] || params["hormones"] || %{})
    vec = Emotion.build_vector(mood, hormones)
    bucket = Emotion.bucket(num(mood["valence"], 0.0), num(mood["arousal"], 0.5), num(mood["dominance"], 0.5))

    %AgentState{}
    |> AgentState.changeset(%{
      agent_id: agent_id,
      status: "active",
      current_emotional: Pgvector.new(vec),
      current_bucket: bucket,
      metrics: %{"mood" => mood, "hormones" => hormones},
      last_bucket_refresh: DateTime.utc_now()
    })
    |> Repo.insert(
      on_conflict: {:replace, [:current_emotional, :current_bucket, :metrics, :last_bucket_refresh, :updated_at]},
      conflict_target: :agent_id
    )

    {:ok, mood_get(agent_id)}
  end

  @doc """
  Path-explanation (ADR-006): for each target memory, the best graph path from `from_id` via the
  active GraphStore adapter, as a hop chain `[%{edge_type, weight, node_id}]` (the Accords'
  "recalled because A→causal→B" surface). Tenant-checked: `from_id` and every explained target must
  belong to the agent. Returns `%{from: id, paths: %{target_id => [hop]}}`.
  """
  def explain_paths(agent_id, from_id, to_ids, opts \\ []) do
    targets = List.wrap(to_ids)

    with {:ok, _from} <- fetch_owned_memory(agent_id, from_id),
         owned when owned != [] <- owned_ids(agent_id, targets),
         {:ok, chains} <- GraphStore.explain_paths([from_id], owned, opts) do
      {:ok, %{from: from_id, paths: Map.new(chains, fn {t, chain} -> {t, Enum.map(chain, &hop_view/1)} end)}}
    else
      [] -> {:ok, %{from: from_id, paths: %{}}}
      other -> other
    end
  end

  @doc "List the agent's access compartments."
  def compartments(agent_id) do
    Repo.all(from(c in Compartment, where: c.owner_agent == ^agent_id, order_by: [asc: c.slug]))
    |> Enum.map(fn c ->
      %{id: c.id, slug: c.slug, classification: to_string(c.classification), settings: c.settings}
    end)
  end

  # ── serializers (contract node/edge shapes) ─────────────────────
  @doc false
  def node_view(m) do
    %{
      id: m.id,
      # Non-null per the frontend MemoryNode type; "" (not content) because the frontend supplies
      # its own label fallbacks (content_type, id, "—") for a memory with no authored summary.
      summary: m.summary || "",
      content_type: to_string(m.content_type),
      state: to_string(m.state),
      compartment: m.compartment,
      salience: roundf(m.salience),
      decay_weight: roundf(m.decay_weight),
      pinned: m.pinned,
      valence: roundf(m.valence),
      arousal: roundf(m.arousal),
      recall_count: m.recall_count,
      occurred_at: iso(m.occurred_at)
    }
  end

  @doc false
  def edge_view(e) do
    %{
      id: e.id,
      source: e.source_memory_id,
      target: e.target_memory_id,
      type: to_string(e.edge_type),
      weight: roundf(e.weight),
      reinforcement_count: e.reinforcement_count,
      last_reinforced_at: iso(e.last_reinforced_at)
    }
  end

  defp hop_view(%{edge_type: type, weight: w, node_id: node_id}) do
    %{edge_type: if(type, do: to_string(type), else: nil), weight: roundf(w), node_id: node_id}
  end

  # ── internals ───────────────────────────────────────────────────
  defp owned_ids(agent_id, ids) do
    valid = Enum.filter(ids, &match?({:ok, _}, cast_uuid(&1)))

    if valid == [],
      do: [],
      else: Repo.all(from(m in Memory, where: m.id in ^valid and m.owner_agent == ^agent_id, select: m.id))
  end

  defp fetch_owned_edge(agent_id, edge_id) do
    with {:ok, id} <- cast_uuid(edge_id),
         %AssociationEdge{} = e <- Repo.get(AssociationEdge, id) do
      if owns?(agent_id, e.source_memory_id) and owns?(agent_id, e.target_memory_id),
        do: {:ok, e},
        else: {:error, :forbidden}
    else
      nil -> {:error, :not_found}
      :error -> {:error, :not_found}
    end
  end

  defp fetch_owned_memory(agent_id, memory_id) do
    with {:ok, id} <- cast_uuid(memory_id),
         %Memory{} = m <- Repo.get(Memory, id) do
      if m.owner_agent == agent_id, do: {:ok, m}, else: {:error, :forbidden}
    else
      nil -> {:error, :not_found}
      :error -> {:error, :not_found}
    end
  end

  defp nudge(agent_id, memory_id, fun) do
    with {:ok, _id} <- cast_uuid(memory_id),
         {:ok, _weight} <- fun.(memory_id, %{owner_agent: agent_id}),
         %Memory{} = mem <- Repo.get(Memory, memory_id) do
      {:ok, node_view(mem)}
    else
      :error -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :not_found}
    end
  end

  defp set_state(agent_id, memory_id, fun) do
    with {:ok, _id} <- cast_uuid(memory_id),
         :ok <- fun.(memory_id, %{owner_agent: agent_id}),
         %Memory{} = mem <- Repo.get(Memory, memory_id) do
      {:ok, node_view(mem)}
    else
      :error -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :not_found}
    end
  end

  defp owns?(agent_id, memory_id) do
    Repo.exists?(from(m in Memory, where: m.id == ^memory_id and m.owner_agent == ^agent_id))
  end

  defp maybe_change(changes, attrs, key, fun) do
    if Map.has_key?(attrs, key), do: Map.put(changes, key, fun.(attrs[key])), else: changes
  end

  defp normalize_attrs(attrs, keys) do
    Enum.reduce(keys, %{}, fn k, acc ->
      cond do
        Map.has_key?(attrs, k) -> Map.put(acc, k, attrs[k])
        Map.has_key?(attrs, to_string(k)) -> Map.put(acc, k, attrs[to_string(k)])
        true -> acc
      end
    end)
  end

  defp stringify_nums(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), num(v, nil)} end)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp stringify_nums(_), do: %{}

  defp cast_uuid(v) do
    case Ecto.UUID.cast(v) do
      {:ok, u} -> {:ok, u}
      :error -> :error
    end
  end

  defp opt_float(nil, default), do: default
  defp opt_float(v, _default) when is_number(v), do: v * 1.0
  defp opt_float(v, default) when is_binary(v), do: (case Float.parse(v) do {f, _} -> f; :error -> default end)
  defp opt_float(_, default), do: default

  defp opt_int(nil, default), do: default
  defp opt_int(v, _default) when is_integer(v), do: v
  defp opt_int(v, default) when is_binary(v), do: (case Integer.parse(v) do {n, _} -> n; :error -> default end)
  defp opt_int(_, default), do: default

  defp clamp_int(v, lo, hi), do: v |> max(lo) |> min(hi)
  defp clampf(v, lo, hi) when is_number(v), do: v |> max(lo) |> min(hi)
  defp clampf(_, _lo, hi), do: hi

  defp to_f(v) when is_number(v), do: v * 1.0
  defp to_f(v) when is_binary(v), do: (case Float.parse(v) do {f, _} -> f; :error -> 0.0 end)
  defp to_f(_), do: 0.0

  defp num(v, _default) when is_number(v), do: v * 1.0
  defp num(v, default) when is_binary(v), do: (case Float.parse(v) do {f, _} -> f; :error -> default end)
  defp num(_, default), do: default

  defp truthy(true), do: true
  defp truthy("true"), do: true
  defp truthy(1), do: true
  defp truthy(_), do: false

  defp roundf(v) when is_number(v), do: Float.round(v * 1.0, 4)
  defp roundf(_), do: nil

  defp round6(v) when is_number(v), do: Float.round(v * 1.0, 6)
  defp round6(_), do: 0.0

  defp iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp iso(_), do: nil
end
