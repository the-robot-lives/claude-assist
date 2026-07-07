defmodule TheRobotRemembers.GraphStoreDbTest do
  @moduledoc """
  DB-backed coverage of the default (CTE) GraphStore adapter — runnable without Apache AGE, since it
  is plain SQL over `association_edges`. Confirms `rank_list/2` reaches connected memories,
  `neighborhood/3` yields the reachable set, `subgraph/2` fetches owner-scoped nodes+edges, and
  `explain_paths/3` returns hop chains — and that recall still works through the seam.

  The `:age`↔`:cte` parity check is `@tag :age` (excluded by default; needs a database with AGE +
  `AGE_GRAPH_ENABLED=true` and a backfilled projection).
  """
  use TheRobotRemembers.DataCase, async: false

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.Memory.GraphStore
  alias TheRobotRemembers.Memory.GraphStore.{CTE, AGE}
  alias TheRobotRemembers.Memory.GraphMirror
  alias TheRobotRemembers.Schema.Memory.AssociationEdge
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema

  # Insert memories DIRECTLY (bypassing Memory.remember → the inline Weaver, which would add its own
  # emotional/temporal edges) so the graph under test contains only the edges each test creates.
  defp mem!(owner, content) do
    {:ok, m} =
      %MemSchema{}
      |> MemSchema.changeset(%{
        owner_agent: owner,
        content: content,
        state: :active,
        emotional_embedding: Pgvector.new([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        valence: 0.0,
        arousal: 0.0,
        dominance: 0.0,
        cortisol: 0.0,
        dopamine: 0.0,
        oxytocin: 0.0,
        serotonin: 0.0
      })
      |> Repo.insert()

    m.id
  end

  defp edge!(src, tgt, weight) do
    {:ok, e} =
      %AssociationEdge{}
      |> AssociationEdge.changeset(%{
        source_memory_id: src,
        target_memory_id: tgt,
        edge_type: :semantic,
        weight: weight,
        last_reinforced_at: DateTime.utc_now()
      })
      |> Repo.insert()

    e
  end

  describe "CTE adapter (default seam)" do
    test "rank_list/2 reaches memories connected within the hop/weight budget, with path scores" do
      a = mem!("aria", "alpha")
      b = mem!("aria", "beta")
      c = mem!("aria", "gamma")
      edge!(a, b, 0.6)
      edge!(b, c, 0.6)

      assert {:ok, results} = GraphStore.rank_list([a], min_weight: 0.2, max_hops: 3, fanout: 8, limit: 50)
      ids = Enum.map(results, & &1.memory_id)
      assert b in ids and c in ids
      assert Enum.all?(results, &(is_float(&1.score) and &1.score > 0.0 and &1.score <= 1.0))
    end

    test "rank_list/2 respects the weight threshold" do
      a = mem!("aria", "alpha")
      b = mem!("aria", "weak neighbor")
      edge!(a, b, 0.1)

      assert {:ok, results} = GraphStore.rank_list([a], min_weight: 0.2, max_hops: 3, fanout: 8, limit: 50)
      refute b in Enum.map(results, & &1.memory_id)
    end

    test "neighborhood/3 returns the reachable ids incl. the seed" do
      a = mem!("aria", "alpha")
      b = mem!("aria", "beta")
      edge!(a, b, 0.6)

      assert {:ok, ids} = GraphStore.neighborhood(a, 2, min_weight: 0.2)
      assert a in ids and b in ids
    end

    test "subgraph/2 fetches owner-scoped node + edge structs" do
      a = mem!("aria", "alpha")
      b = mem!("aria", "beta")
      _other = mem!("marcus", "foreign")
      edge!(a, b, 0.6)

      assert {:ok, %{nodes: nodes, edges: edges, truncated: false}} =
               GraphStore.subgraph("aria", min_weight: 0.2, limit: 500, candidate_ids: :all)

      node_ids = Enum.map(nodes, & &1.id)
      assert a in node_ids and b in node_ids
      assert Enum.all?(edges, &(&1.source_memory_id in node_ids and &1.target_memory_id in node_ids))
    end

    test "explain_paths/3 returns a hop chain per target" do
      a = mem!("aria", "alpha")
      b = mem!("aria", "beta")
      edge!(a, b, 0.7)

      assert {:ok, chains} = CTE.explain_paths([a], [b], min_weight: 0.2, max_hops: 3, fanout: 8)
      assert [hop | _] = chains[b]
      assert hop.node_id == b
      assert hop.edge_type == :semantic
      assert hop.weight >= 0.2
    end
  end

  describe "recall through the seam" do
    test "active recall still expands via the graph path (adapter :cte)" do
      _a = mem!("aria", "postgres deadlock in the pool")
      _b = mem!("aria", "the connection pool outage")

      assert GraphStore.adapter_name() == :cte
      {:ok, %{results: results}} = Memory.recall("postgres deadlock", [limit: 8], %{owner_agent: "aria"})
      assert results != []
    end
  end

  # ── live AGE parity (opt-in) ────────────────────────────────────
  @tag :age
  test ":age rank_list is a superset of :cte on a seeded fixture" do
    # Requires AGE + AGE_GRAPH_ENABLED=true. Seed a small owner graph, project it, and compare the
    # two adapters directly (AGE has no fan-out cap, so its result set should contain the CTE's).
    a = mem!("aria", "alpha")
    b = mem!("aria", "beta")
    c = mem!("aria", "gamma")
    edge!(a, b, 0.6)
    edge!(b, c, 0.6)

    Application.put_env(
      :the_robot_remembers,
      :age_graph,
      Keyword.merge(Application.get_env(:the_robot_remembers, :age_graph, []), enabled: true)
    )

    GraphMirror.backfill()

    {:ok, cte} = CTE.rank_list([a], min_weight: 0.2, max_hops: 3, fanout: 8, limit: 50)
    {:ok, age} = AGE.rank_list([a], min_weight: 0.2, max_hops: 3, limit: 50)

    cte_ids = MapSet.new(cte, & &1.memory_id)
    age_ids = MapSet.new(age, & &1.memory_id)

    assert MapSet.size(MapSet.intersection(cte_ids, age_ids)) > 0
    assert MapSet.subset?(cte_ids, age_ids), "AGE (no fan-out cap) should contain the CTE result set"
  end
end
