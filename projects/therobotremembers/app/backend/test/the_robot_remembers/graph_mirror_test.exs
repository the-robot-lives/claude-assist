defmodule TheRobotRemembers.GraphMirrorTest do
  @moduledoc """
  Unit coverage for the Apache AGE projection's pure surface: flag gating (`Repo.AGE` /
  `GraphMirror.enabled?`) and cypher/SQL construction. These need neither AGE nor a database — the
  builders are pure functions and the gate reads application config.

  The live round-trip lives in `TheRobotRemembers.GraphMirrorAgeTest` (tagged `@tag :age`, excluded
  by default), mirroring the opt-in `:weaviate` suite.
  """
  use ExUnit.Case, async: true

  alias TheRobotRemembers.Memory.GraphMirror
  alias TheRobotRemembers.Repo.AGE

  @u1 "550e8400-e29b-41d4-a716-446655440000"
  @u2 "550e8400-e29b-41d4-a716-446655440001"

  setup do
    original = Application.get_env(:the_robot_remembers, :age_graph)
    on_exit(fn -> Application.put_env(:the_robot_remembers, :age_graph, original) end)
    :ok
  end

  defp put_age(kvs) do
    merged = Keyword.merge(Application.get_env(:the_robot_remembers, :age_graph, []), kvs)
    Application.put_env(:the_robot_remembers, :age_graph, merged)
  end

  describe "flag gating" do
    test "disabled by default in the test env" do
      refute GraphMirror.enabled?()
      refute AGE.enabled?()
    end

    test "enabled? follows the runtime flag" do
      put_age(enabled: true)
      assert GraphMirror.enabled?()
      put_age(enabled: false)
      refute GraphMirror.enabled?()
    end

    test "graph_name defaults to trr_memory" do
      assert AGE.graph_name() == "trr_memory"
    end

    test "enqueue helpers are safe no-ops when disabled" do
      # Disabled: return :ok and never touch Oban.
      assert GraphMirror.enqueue_sync([@u1]) == :ok
      assert GraphMirror.enqueue_sync([]) == :ok
      assert GraphMirror.enqueue_sync(nil) == :ok
      assert GraphMirror.enqueue_reconcile() == :ok
      assert GraphMirror.enqueue_backfill() == :ok
    end
  end

  describe "Repo.AGE.after_connect/1" do
    test "no-ops (never touches the connection) when disabled" do
      # If the hook tried to run Postgrex against this bogus conn it would raise; disabled => :ok.
      assert AGE.after_connect(:not_a_real_conn) == :ok
    end
  end

  describe "vertex cypher" do
    test "MERGEs by ext_id and sets owner_agent, scoped to the graph" do
      sql = GraphMirror.vertex_sql(@u1, "aria")
      assert sql =~ "cypher('trr_memory'"
      assert sql =~ "MERGE (m:Memory {ext_id: '#{@u1}'})"
      assert sql =~ "SET m.owner_agent = 'aria'"
      assert sql =~ "AS (result agtype)"
    end

    test "escapes single quotes in owner_agent" do
      assert GraphMirror.vertex_sql(@u1, "ari'a") =~ ~S(SET m.owner_agent = 'ari\'a')
    end

    test "raises on an invalid uuid" do
      assert_raise ArgumentError, ~r/invalid UUID/, fn -> GraphMirror.vertex_sql("nope", "x") end
    end
  end

  describe "edge upsert cypher" do
    test "MATCHes both endpoints via the index-friendly WHERE form and MERGEs the typed edge" do
      sql = GraphMirror.edge_upsert_sql(@u1, @u2, :semantic, 0.5, 3, ~U[2026-07-05 00:00:00Z])
      assert sql =~ "MATCH (s:Memory), (t:Memory) WHERE s.ext_id = '#{@u1}' AND t.ext_id = '#{@u2}'"
      assert sql =~ "MERGE (s)-[r:SEMANTIC]->(t)"
      assert sql =~ "SET r.weight = 0.5, r.reinforcement_count = 3"
      assert sql =~ "r.last_reinforced_at = '2026-07-05T00:00:00Z'"
    end

    test "upper-cases each edge_type to its AGE label (atom or string)" do
      for {type, label} <- [semantic: "SEMANTIC", co_occurrence: "CO_OCCURRENCE", tangent: "TANGENT"] do
        assert GraphMirror.edge_upsert_sql(@u1, @u2, type, 0.3, 0, "t") =~ "[r:#{label}]"
      end

      assert GraphMirror.edge_upsert_sql(@u1, @u2, "emotional", 0.9, 0, "t") =~ "[r:EMOTIONAL]"
    end

    test "clamps weight into [0,1]" do
      assert GraphMirror.edge_upsert_sql(@u1, @u2, :causal, 1.7, 0, "t") =~ "r.weight = 1.0"
      assert GraphMirror.edge_upsert_sql(@u1, @u2, :causal, -0.3, 0, "t") =~ "r.weight = 0.0"
    end

    test "raises on an unknown edge_type" do
      assert_raise ArgumentError, ~r/unknown edge_type/, fn ->
        GraphMirror.edge_upsert_sql(@u1, @u2, :bogus, 0.5, 0, "t")
      end
    end
  end

  describe "edge / vertex removal cypher" do
    test "edge_remove_sql matches the directed typed edge and DELETEs it" do
      sql = GraphMirror.edge_remove_sql(@u1, @u2, :temporal)
      assert sql =~ "MATCH (s:Memory)-[r:TEMPORAL]->(t:Memory)"
      assert sql =~ "WHERE s.ext_id = '#{@u1}' AND t.ext_id = '#{@u2}'"
      assert sql =~ "DELETE r"
    end

    test "vertex_delete_sql DETACH DELETEs by ext_id" do
      sql = GraphMirror.vertex_delete_sql(@u1)
      assert sql =~ "MATCH (m:Memory) WHERE m.ext_id = '#{@u1}'"
      assert sql =~ "DETACH DELETE m"
    end
  end
end

defmodule TheRobotRemembers.GraphMirrorAgeTest do
  @moduledoc """
  Live Apache AGE round-trip. Opt-in — excluded by default. Requires a database with AGE installed,
  Liquibase 031 applied, and AGE_GRAPH_ENABLED=true so `Repo.AGE.after_connect/1` runs `LOAD 'age'`
  when the pool opens its connections:

      AGE_GRAPH_ENABLED=true mix test --include age test/the_robot_remembers/graph_mirror_test.exs
  """
  use TheRobotRemembers.DataCase, async: false
  @moduletag :age

  alias TheRobotRemembers.Memory.GraphMirror
  alias TheRobotRemembers.Repo.AGE

  setup do
    merged = Keyword.merge(Application.get_env(:the_robot_remembers, :age_graph, []), enabled: true)
    Application.put_env(:the_robot_remembers, :age_graph, merged)
    :ok
  end

  test "a Memory vertex MERGE round-trips through the live graph" do
    ext_id = Ecto.UUID.generate()
    Ecto.Adapters.SQL.query!(Repo, GraphMirror.vertex_sql(ext_id, "age_itest"), [])

    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(
        Repo,
        "SELECT ext_id::text FROM cypher('#{AGE.graph_name()}', $c$ " <>
          "MATCH (m:Memory) WHERE m.ext_id = '#{ext_id}' RETURN m.ext_id $c$) AS (ext_id agtype);",
        []
      )

    assert Enum.any?(rows, fn [v] -> is_binary(v) and v =~ ext_id end),
           "the merged vertex should be readable back by ext_id"
  end
end
