defmodule TheRobotRemembers.MemoryScaleTest do
  @moduledoc """
  Large-scale write + recall over a generated corpus: ~1024 agent-bound memories spanning a
  simulated year, across many users / tasks / moods (`Memory.Seeds.generate/1`). Exercises the
  write path at scale (each `remember/2` runs embedding-activation + the Weaver inline under
  `Oban testing: :inline`) and the recall paths (emotional resonance, lexical content, graph),
  reinforcement, archive, and **agent binding** (recall is scoped to the owning agent).

  Count is overridable via `TRR_SCALE_COUNT` for quick iteration; default 1024.
  """
  use TheRobotRemembers.DataCase, async: false

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.Memory.Seeds
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema
  alias TheRobotRemembers.Schema.Memory.AssociationEdge

  @count String.to_integer(System.get_env("TRR_SCALE_COUNT", "1024"))
  @agent_a %{owner_agent: "assistant-a", requester_id: "assistant-a"}
  @agent_b %{owner_agent: "assistant-b", requester_id: "assistant-b"}

  @tag timeout: 600_000
  test "writes ~#{@count} agent-bound memories over a simulated year and recalls them" do
    corpus = Seeds.generate(count: @count, days: 365, seed: 42)

    {us, _} =
      :timer.tc(fn ->
        Enum.each(corpus, fn attrs -> {:ok, _} = Memory.remember(attrs, @agent_a) end)
      end)

    IO.puts("\n[scale] wrote #{@count} memories in #{Float.round(us / 1_000_000, 1)}s")

    # a small second agent's corpus, to prove agent binding / isolation
    Seeds.generate(count: 24, days: 365, seed: 99)
    |> Enum.each(fn attrs -> {:ok, _} = Memory.remember(attrs, @agent_b) end)

    rows_a = Repo.all(from m in MemSchema, where: m.owner_agent == "assistant-a")

    # ── write feature: scale + distribution ───────────────────────
    assert length(rows_a) == @count
    assert Enum.all?(rows_a, &(&1.state == :active)), "inline embedding worker should activate every memory"

    valences = Enum.map(rows_a, & &1.valence)
    assert Enum.min(valences) < -0.3 and Enum.max(valences) > 0.3, "moods should span negative..positive"

    times = Enum.map(rows_a, & &1.occurred_at)
    span_days = div(DateTime.diff(Enum.max(times, DateTime), Enum.min(times, DateTime), :second), 86_400)
    assert span_days > 300, "memories should span most of the simulated year (got #{span_days}d)"

    domains = rows_a |> Enum.map(& &1.domain) |> Enum.uniq()
    assert length(domains) >= 8, "varied task domains"

    collaborators = rows_a |> Enum.flat_map(& &1.collaborators) |> Enum.uniq()
    assert length(collaborators) >= 8, "varied collaborators (users)"

    # ── Weaver built an association graph at scale ────────────────
    edge_types =
      Repo.all(
        from e in AssociationEdge,
          join: m in MemSchema,
          on: m.id == e.source_memory_id,
          where: m.owner_agent == "assistant-a",
          group_by: e.edge_type,
          select: {e.edge_type, count(e.id)}
      )
      |> Map.new()

    IO.puts("[scale] edges by type: #{inspect(edge_types)}")
    assert Map.get(edge_types, :emotional, 0) > 0
    assert Map.get(edge_types, :contextual, 0) > 0

    # ── recall: emotional resonance over the full corpus ──────────
    {:ok, %{results: frustrated}} =
      Memory.recall_by_emotion(%{mood: %{valence: -0.7, arousal: 0.8, dominance: 0.3}}, [limit: 10], @agent_a)

    neg = Enum.count(frustrated, &(&1.valence < 0))
    assert neg >= 7, "a frustrated state should mostly surface negative-valence memories (got #{neg}/10)"
    assert frustrated |> Enum.map(& &1.resonance) |> non_increasing?()

    {:ok, %{results: happy}} =
      Memory.recall_by_emotion(%{mood: %{valence: 0.85, arousal: 0.6, dominance: 0.85}}, [limit: 10], @agent_a)

    pos = Enum.count(happy, &(&1.valence > 0))
    assert pos >= 7, "a triumphant state should mostly surface positive-valence memories (got #{pos}/10)"

    # ── recall: lexical content over the full corpus ──────────────
    {:ok, %{results: deadlocks}} = Memory.recall("Postgres deadlock", [limit: 10], @agent_a)
    assert Enum.any?(deadlocks, &String.contains?(&1.content || "", "deadlock"))

    # ── agent binding: recall is scoped to the owning agent ───────
    a_ids = MapSet.new(rows_a, & &1.id)

    {:ok, %{results: a_recall}} =
      Memory.recall_by_emotion(%{mood: %{valence: 0.0, arousal: 0.5, dominance: 0.5}}, [limit: 50], @agent_a)

    assert Enum.all?(a_recall, &MapSet.member?(a_ids, &1.id)), "agent A recall must only return agent A memories"

    {:ok, %{results: b_recall}} =
      Memory.recall_by_emotion(%{mood: %{valence: 0.0, arousal: 0.5, dominance: 0.5}}, [limit: 50], @agent_b)

    refute Enum.any?(b_recall, &MapSet.member?(a_ids, &1.id)), "agent B must not see agent A memories"
    assert b_recall != []

    # ── reinforcement at scale (inline ReinforcementWorker) ───────
    before_co =
      Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)

    {:ok, %{results: r}} =
      Memory.recall_by_emotion(%{mood: %{valence: -0.6, arousal: 0.7, dominance: 0.3}}, [limit: 5], @agent_a)

    assert Enum.any?(r, fn x -> Repo.get(MemSchema, x.id).recall_count >= 1 end)
    after_co = Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)
    assert after_co > before_co, "recall should create Hebbian co_occurrence edges"

    # ── archive excludes from recall ──────────────────────────────
    victim = hd(frustrated).id
    :ok = Memory.archive(victim, @agent_a)

    {:ok, %{results: after_archive}} =
      Memory.recall_by_emotion(%{mood: %{valence: -0.7, arousal: 0.8, dominance: 0.3}}, [limit: 10], @agent_a)

    refute Enum.any?(after_archive, &(&1.id == victim)), "archived memory must not be recalled"
  end

  defp non_increasing?(list), do: list == Enum.sort(list, :desc)
end
