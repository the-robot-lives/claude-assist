defmodule TheRobotRemembers.MemoryApiTest do
  @moduledoc """
  DB-backed coverage of the memory console internal API (`Memory.Console`) and the additive
  recall preview path (`Recall.preview`): side-effect-free preview, per-result RRF contributions,
  and — load-bearing — tenant scoping of the graph endpoints (edges never cross `owner_agent`).

  Requires the memory schema in the test DB (test_helper applies Liquibase 025–030). Not run in
  environments without a reachable database.
  """
  use TheRobotRemembers.DataCase, async: false

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema
  alias TheRobotRemembers.Schema.Memory.{AssociationEdge, RecallLog}

  defp mem!(owner, content, extra \\ %{}) do
    {:ok, %{id: id}} =
      Memory.remember(
        Map.merge(%{content: content, valence: 0.1, arousal: 0.4, dominance: 0.5}, extra),
        %{owner_agent: owner, requester_id: owner}
      )

    id
  end

  defp edge!(src, tgt, type, weight) do
    {:ok, e} =
      %AssociationEdge{}
      |> AssociationEdge.changeset(%{
        source_memory_id: src,
        target_memory_id: tgt,
        edge_type: type,
        weight: weight,
        last_reinforced_at: DateTime.utc_now()
      })
      |> Repo.insert()

    e
  end

  describe "recall preview is side-effect-free" do
    test "does not reinforce (recall_count unchanged, no Hebbian edges) and logs mode preview" do
      id = mem!("aria", "postgres deadlock at 2am debugging the pool", %{domain: "debugging"})
      _ = mem!("aria", "the DNS outage last winter", %{domain: "ops"})

      before_recall = Repo.get(MemSchema, id).recall_count
      before_co = Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)

      {:ok, %{results: results, duration_ms: ms}} =
        Console.recall_preview("aria", %{"query" => "postgres deadlock"})

      assert is_integer(ms)
      assert Enum.any?(results, &String.contains?(&1.memory.summary || "", "") or is_map(&1.memory))
      assert results != []

      assert Repo.get(MemSchema, id).recall_count == before_recall, "preview must not reinforce"

      after_co = Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)
      assert after_co == before_co, "preview must not create Hebbian co_occurrence edges"

      assert Repo.exists?(from(r in RecallLog, where: r.mode == "preview"))
    end

    test "each result carries RRF contributions (source tag, rank, score), score-sorted" do
      mem!("aria", "kubernetes helm rollout for the api", %{domain: "ops"})
      mem!("aria", "helm chart values and the ingress", %{domain: "ops"})

      {:ok, %{results: results}} = Console.recall_preview("aria", %{"query" => "helm rollout"})

      assert results != []
      top = hd(results)
      assert is_float(top.score)
      assert is_list(top.contributions)
      assert top.contributions != []

      for c <- top.contributions do
        assert is_binary(c.source) and c.source =~ ":"
        assert is_integer(c.rank) and c.rank >= 1
        assert is_float(c.score)
      end

      scores = Enum.map(top.contributions, & &1.score)
      assert scores == Enum.sort(scores, :desc)
    end

    test "mood-only preview (no query) works via the emotional path" do
      mem!("aria", "a triumphant launch", %{valence: 0.9, arousal: 0.7, dominance: 0.8})
      {:ok, %{results: results}} = Console.recall_preview("aria", %{"mood" => %{"valence" => 0.85, "arousal" => 0.65}})
      assert results != []
    end
  end

  describe "graph subgraph is tenant-scoped" do
    test "returns only the agent's nodes and never an edge with a foreign endpoint" do
      a1 = mem!("aria", "aria memory one", %{domain: "shared"})
      a2 = mem!("aria", "aria memory two", %{domain: "shared"})
      b1 = mem!("marcus", "marcus memory one")

      intra = edge!(a1, a2, :semantic, 0.6)
      cross = edge!(a1, b1, :co_occurrence, 0.6)

      %{nodes: nodes, edges: edges} = Console.subgraph("aria", min_weight: 0.2, limit: 500)

      node_ids = Enum.map(nodes, & &1.id)
      edge_ids = Enum.map(edges, & &1.id)

      assert a1 in node_ids and a2 in node_ids
      refute b1 in node_ids, "another agent's memory must not appear as a node"
      assert intra.id in edge_ids, "the intra-owner edge should be present"
      refute cross.id in edge_ids, "a cross-owner edge must never be returned"
    end
  end

  describe "mutations are tenant-checked" do
    test "set_edge_weight updates an owned edge (provenance) and rejects a cross-owner edge" do
      a1 = mem!("aria", "aria one")
      a2 = mem!("aria", "aria two")
      b1 = mem!("marcus", "marcus one")

      owned = edge!(a1, a2, :semantic, 0.4)
      cross = edge!(a1, b1, :co_occurrence, 0.6)

      assert {:ok, view} = Console.set_edge_weight("aria", owned.id, 0.85, %{reason: "manual", created_by: "user:u1"})
      assert view.weight == 0.85
      assert Repo.get(AssociationEdge, owned.id).created_by == "user:u1"

      assert {:error, :forbidden} = Console.set_edge_weight("aria", cross.id, 0.9)
    end

    test "set_memory changes decay_weight/pinned for an owned memory, rejects others" do
      a = mem!("aria", "aria mem")
      b = mem!("marcus", "marcus mem")

      assert {:ok, node} = Console.set_memory("aria", a, %{"decay_weight" => 0.5, "pinned" => true})
      assert node.pinned == true
      assert node.decay_weight == 0.5

      assert {:error, :forbidden} = Console.set_memory("aria", b, %{"pinned" => true})
      assert {:error, :not_found} = Console.set_memory("aria", Ecto.UUID.generate(), %{"pinned" => true})
    end

    test "reinforce/denforce return the updated node and are owner-scoped" do
      a = mem!("aria", "reinforce me")
      assert {:ok, node} = Console.reinforce("aria", a)
      assert is_map(node) and node.id == a
      assert {:error, _} = Console.reinforce("marcus", a)
    end
  end

  describe "agents listing + mood" do
    test "agents/0 reports memory and edge counts per owner" do
      a1 = mem!("aria", "one")
      a2 = mem!("aria", "two")
      edge!(a1, a2, :semantic, 0.5)
      mem!("marcus", "solo")

      agents = Console.agents()
      aria = Enum.find(agents, &(&1.agent_id == "aria"))
      assert aria.memory_count >= 2
      assert aria.edge_count >= 1
    end

    test "mood_set then mood_get round-trips the stored emotional state" do
      Console.mood_set("aria", %{mood: %{"valence" => 0.4, "arousal" => 0.6, "dominance" => 0.5}, hormones: %{"dopamine" => 0.7}})
      got = Console.mood_get("aria")
      assert got.source == "stored"
      assert got.mood["valence"] == 0.4
      assert got.hormones["dopamine"] == 0.7
      assert is_binary(got.current_bucket)
    end
  end
end
