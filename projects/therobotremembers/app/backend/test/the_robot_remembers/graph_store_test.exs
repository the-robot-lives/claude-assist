defmodule TheRobotRemembers.GraphStoreTest do
  @moduledoc """
  Pure (no-DB) coverage of the Phase-B graph seam: adapter selection, boot validation, and the
  CTE/AGE query builders (including the Dreamer-groundwork `link_candidates` cypher). Live
  traversal/subgraph/explanation against Apache AGE is covered by @tag :age DB tests and needs a
  database with AGE.
  """
  use ExUnit.Case, async: true

  alias TheRobotRemembers.Memory.GraphStore
  alias TheRobotRemembers.Memory.GraphStore.{CTE, AGE}
  alias TheRobotRemembers.Bench.GraphBench

  @u1 "550e8400-e29b-41d4-a716-446655440000"
  @u2 "550e8400-e29b-41d4-a716-446655440001"

  defp norm(sql), do: sql |> String.replace(~r/\s+/, " ") |> String.trim()

  setup do
    original = %{
      graph_store: Application.get_env(:the_robot_remembers, :graph_store),
      age_graph: Application.get_env(:the_robot_remembers, :age_graph)
    }

    on_exit(fn -> Enum.each(original, fn {k, v} -> Application.put_env(:the_robot_remembers, k, v) end) end)
    :ok
  end

  defp put(key, kvs) do
    merged = Keyword.merge(Application.get_env(:the_robot_remembers, key, []), kvs)
    Application.put_env(:the_robot_remembers, key, merged)
  end

  describe "adapter selection + boot validation" do
    test "defaults to the CTE adapter and validates cleanly" do
      assert GraphStore.adapter() == CTE
      assert GraphStore.adapter_name() == :cte
      assert GraphStore.validate!() == :ok
    end

    test "validate!/0 raises when :age is selected without the AGE layer" do
      put(:graph_store, adapter: :age)
      put(:age_graph, enabled: false)
      assert_raise RuntimeError, ~r/AGE graph layer is disabled/, fn -> GraphStore.validate!() end
    end

    test ":age with the AGE layer enabled validates and routes to the AGE adapter" do
      put(:graph_store, adapter: :age)
      put(:age_graph, enabled: true)
      assert GraphStore.validate!() == :ok
      assert GraphStore.adapter() == AGE
      assert GraphStore.adapter_name() == :age
    end
  end

  describe "CTE adapter SQL" do
    test "rank_list_sql is the recall spreading-activation CTE, verbatim (matches the benchmark copy)" do
      assert norm(CTE.rank_list_sql()) == norm(GraphBench.cte_sql()),
             "GraphStore.CTE must run the exact recall CTE — the seam must not change semantics"
    end

    test "neighborhood_sql is the bidirectional reachable-id walk" do
      sql = CTE.neighborhood_sql()
      assert sql =~ "WITH RECURSIVE walk(memory_id, depth)"
      assert sql =~ "SELECT DISTINCT memory_id::text FROM walk"
    end

    test "explain_sql restricts the walk to the target set and returns the full path" do
      sql = CTE.explain_sql()
      assert sql =~ "(path || memory_id)::text[]"
      assert sql =~ "memory_id = ANY(string_to_array($5, ',')::uuid[])"
    end
  end

  describe "AGE adapter cypher" do
    test "rank_list_cypher builds the variable-length traversal with a path-product floor" do
      cy = AGE.rank_list_cypher([@u1, @u2], min_weight: 0.2, max_hops: 3, limit: 25)
      assert cy =~ "MATCH p = (s:Memory)-[*1..3]-(m:Memory)"
      assert cy =~ "s.ext_id IN ['#{@u1}', '#{@u2}']"
      assert cy =~ "exp(sum(log(r.weight)))"
      assert cy =~ "score >= 0.008"
      assert cy =~ "LIMIT 25"
      assert cy =~ "AS (id agtype, score agtype)"
    end

    test "owner_nodes_cypher / neighborhood_cypher are label-filtered MATCHes" do
      assert AGE.owner_nodes_cypher("aria") =~ "MATCH (m:Memory) WHERE m.owner_agent = 'aria'"
      assert AGE.neighborhood_cypher(@u1, 2, []) =~ "MATCH (s:Memory)-[*0..2]-(m:Memory)"
    end

    test "explain_cypher anchors on the target set and projects node ids + edges + score" do
      cy = AGE.explain_cypher([@u1], [@u2], max_hops: 2)
      assert cy =~ "MATCH p = (s:Memory)-[*1..2]-(m:Memory)"
      assert cy =~ "m.ext_id IN ['#{@u2}']"
      assert cy =~ "[n IN nodes(p) | n.ext_id]"
      assert cy =~ "reduce(acc = 1.0, e IN relationships(p) | acc * e.weight)"
      assert cy =~ "AS (target agtype, node_ids agtype, edges agtype, score agtype)"
    end

    test "raises on an invalid seed uuid" do
      assert_raise ArgumentError, ~r/invalid UUID/, fn -> AGE.rank_list_cypher(["nope"], []) end
    end
  end

  describe "link_candidates cypher (Dreamer groundwork)" do
    test "missing_causal_cypher finds temporal+semantic pairs lacking a causal edge" do
      cy = AGE.missing_causal_cypher("aria", limit: 100)
      assert cy =~ "-[t:TEMPORAL]-"
      assert cy =~ "-[sem:SEMANTIC]-"
      assert cy =~ "NOT (a)-[:CAUSAL]-(b)"
      assert cy =~ "a.owner_agent = 'aria'"
      assert cy =~ "a.ext_id < b.ext_id"
      assert cy =~ "LIMIT 100"
    end

    test "co_recalled_cypher finds unlinked pairs sharing strong neighbors" do
      cy = AGE.co_recalled_cypher("aria", min_weight: 0.4, min_shared: 3)
      assert cy =~ "MATCH (a:Memory)-[r1]-(x:Memory)-[r2]-(b:Memory)"
      assert cy =~ "r1.weight >= 0.4 AND r2.weight >= 0.4"
      assert cy =~ "NOT (a)-[]-(b)"
      assert cy =~ "count(DISTINCT x) AS shared"
      assert cy =~ "shared >= 3"
    end

    test "owner is escaped in link-candidate cypher literals" do
      assert AGE.missing_causal_cypher("ar'ia", []) =~ ~S(a.owner_agent = 'ar\'ia')
    end
  end
end
