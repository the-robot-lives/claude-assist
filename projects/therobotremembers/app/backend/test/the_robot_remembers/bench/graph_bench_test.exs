defmodule TheRobotRemembers.Bench.GraphBenchTest do
  @moduledoc """
  Pure coverage of the benchmark's query-string builders — no database, no AGE. The live
  round-trip smoke test lives in `TheRobotRemembers.Bench.GraphBenchAgeTest` (`@tag :age`,
  excluded by default), mirroring the opt-in `:weaviate` / `:age` suites.
  """
  use ExUnit.Case, async: true

  alias TheRobotRemembers.Bench.GraphBench

  @seeds ["550e8400-e29b-41d4-a716-446655440000", "550e8400-e29b-41d4-a716-446655440001"]

  describe "cte_sql/0 (the recall hot path, verbatim)" do
    test "is the recursive-CTE spreading activation with the recall parameters" do
      sql = GraphBench.cte_sql()

      assert sql =~ "WITH RECURSIVE walk"
      assert sql =~ "JOIN LATERAL"
      # bidirectional expansion over association_edges
      assert sql =~ "e.source_memory_id = w.memory_id OR e.target_memory_id = w.memory_id"
      assert sql =~ "e.weight >= $2", "min-weight threshold is parameterized"
      assert sql =~ "LIMIT $5", "per-node fan-out cap is parameterized"
      assert sql =~ "w.depth < $3", "hop bound is parameterized"
      assert sql =~ "NOT (nxt.memory_id = ANY(w.path))", "cycle guard via path array"
      assert sql =~ "w.path_weight * nxt.weight", "path score is the product of edge weights"
      assert sql =~ "LIMIT $4", "top-K is parameterized"
    end
  end

  describe "age_traversal_cypher/2" do
    test "anchors on the seed ext_ids and bounds the walk to 3 hops across all labels" do
      cql = GraphBench.age_traversal_cypher(@seeds, 25)

      assert cql =~ "cypher('trr_memory'"
      assert cql =~ "MATCH p = (s:Memory)-[*1..3]-(m:Memory)"
      assert cql =~ "WHERE s.ext_id IN ["
      for s <- @seeds, do: assert(cql =~ "'#{s}'")
    end

    test "accumulates the weighted path score via UNWIND + aggregate (not reduce)" do
      cql = GraphBench.age_traversal_cypher(@seeds, 25)

      assert cql =~ "UNWIND relationships(p) AS r"
      assert cql =~ "exp(sum(log(r.weight)))"
      assert cql =~ "max(path_score)"
      refute cql =~ "reduce(", "portable form must avoid reduce() (AGE >= 1.7.0 only)"
      assert cql =~ "ORDER BY score DESC"
      assert cql =~ "LIMIT 25"
    end

    test "floors the path score at ~0.2^3 and returns two agtype columns" do
      cql = GraphBench.age_traversal_cypher(@seeds, 10)

      assert cql =~ "score >= 0.008"
      assert cql =~ "AS (id agtype, score agtype)"
    end
  end
end

defmodule TheRobotRemembers.Bench.GraphBenchAgeTest do
  @moduledoc """
  Live benchmark smoke test. Opt-in — excluded by default. Requires a database with Apache AGE
  installed and the `trr_memory` graph provisioned (Liquibase 031):

      AGE_GRAPH_ENABLED=true mix test --include age test/the_robot_remembers/bench/graph_bench_test.exs

  `GraphBench` prepares the AGE session itself (`with_age/1`), so it does not depend on the
  `Repo` `after_connect` hook; the flag above only matters if the surrounding app needs it.
  """
  use TheRobotRemembers.DataCase, async: false
  @moduletag :age
  @moduletag timeout: 180_000

  alias TheRobotRemembers.Bench.GraphBench

  setup do
    on_exit(fn -> GraphBench.cleanup() end)
    :ok
  end

  test "both backends return overlapping top results on a tiny synthetic graph" do
    %{ids: ids} = GraphBench.seed(nodes: 100, edges: 300, batch: 100)
    seeds = Enum.take_random(ids, 10)

    {cte_ids, age_ids} = GraphBench.compare_once(seeds)

    assert is_list(cte_ids) and is_list(age_ids)

    assert cte_ids != [] and age_ids != [],
           "both traversals should reach neighbors from 10 seeds in a 300-edge graph"

    assert Enum.any?(cte_ids, &(&1 in age_ids)),
           "CTE and AGE should agree on at least one recalled memory"
  end

  test "run/1 reports per-backend percentile stats" do
    %{ids: ids} = GraphBench.seed(nodes: 100, edges: 300, batch: 100)

    stats = GraphBench.run(ids: ids, queries: 3, seed_size: 10, warmup: 1)

    assert %{cte: %{p99: _, count: 3}, age: %{p99: _, count: 3}} = stats
  end
end
