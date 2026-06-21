defmodule TheRobotRemembers.WeaviateTest do
  @moduledoc """
  Live integration tests against the cluster Weaviate (`weaviate.noizu.com`). Opt-in:

      DB_* WEAVIATE_API_KEY=… mix test --include weaviate test/the_robot_remembers/weaviate_test.exs

  Excluded from the default run (they hit the network). Uses a dedicated, ephemeral class
  (`TrrMemoryItest`) that is dropped/recreated per test and deleted on exit, and a deterministic
  embedder (feature-hashing) so vectors are reproducible without OpenAI. Covers: named-vector
  upsert + search + update (querying), the remember→Weaviate population flow + semantic active
  recall, and reinforcement/strengthening over Weaviate-recalled entries.
  """
  use TheRobotRemembers.DataCase, async: false

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.Memory.{Embeddings, VectorStore}
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema
  alias TheRobotRemembers.Schema.Memory.AssociationEdge

  @moduletag :weaviate
  @moduletag timeout: 180_000
  @class "TrrMemoryItest"
  @owner "aria_wv"
  @ctx %{owner_agent: @owner, requester_id: @owner}

  setup do
    # Enable Weaviate + a deterministic embedder for this suite only (test_helper disables both).
    put_cfg(:weaviate, enabled: true, class: @class)
    put_cfg(:embeddings, provider: :deterministic)

    # clean slate in Weaviate
    VectorStore.delete_class()
    :ok = VectorStore.ensure_class()
    on_exit(fn -> VectorStore.delete_class() end)
    :ok
  end

  defp put_cfg(key, kvs) do
    merged = Keyword.merge(Application.get_env(:the_robot_remembers, key, []), kvs)
    Application.put_env(:the_robot_remembers, key, merged)
  end

  defp emb(text), do: Embeddings.embed([text]) |> elem(1) |> hd()

  # Weaviate is near-real-time; retry a read until it returns a truthy value (or give up).
  defp eventually(fun, tries \\ 30)
  defp eventually(_fun, 0), do: nil

  defp eventually(fun, tries) do
    case fun.() do
      nil -> Process.sleep(200) && eventually(fun, tries - 1)
      false -> Process.sleep(200) && eventually(fun, tries - 1)
      val -> val
    end
  end

  defp search_for(named, query_text, owner) do
    fn ->
      case VectorStore.search(named, emb(query_text), limit: 5, filters: %{"owner_agent" => owner}) do
        {:ok, hits} when hits != [] -> hits
        _ -> nil
      end
    end
  end

  test "VectorStore: upsert named vectors, nearVector search ranks by similarity, update, count" do
    rust = Ecto.UUID.generate()
    pg = Ecto.UUID.generate()

    :ok = VectorStore.upsert(rust, %{"content" => emb("rust borrow checker ownership lifetimes")}, %{"owner_agent" => @owner})
    :ok = VectorStore.upsert(pg, %{"content" => emb("postgres deadlock connection pool")}, %{"owner_agent" => @owner})

    hits = eventually(search_for("content", "rust ownership", @owner))
    assert hits, "search returned nothing (weaviate not consistent?)"
    assert hd(hits).memory_id == rust, "the rust object should rank first for a rust query"

    # update: re-upsert the same id with different content (POST→PUT-on-conflict path)
    :ok = VectorStore.upsert(rust, %{"content" => emb("kubernetes helm chart rollout")}, %{"owner_agent" => @owner})
    k8s = eventually(fn ->
      case VectorStore.search("content", emb("kubernetes helm"), limit: 5, filters: %{"owner_agent" => @owner}) do
        {:ok, hits} -> Enum.find(hits, &(&1.memory_id == rust))
        _ -> nil
      end
    end)
    assert k8s, "the updated object should match its new content"

    assert {:ok, c} = VectorStore.count()
    assert c == 2, "two distinct objects (update did not duplicate)"
  end

  test "remember populates Weaviate and active recall uses the semantic named-vector path" do
    {:ok, _} =
      Memory.remember(%{content: "Aria wrestled the Rust borrow checker and lifetimes all afternoon",
        domain: "engineering", topic: "rust", valence: -0.2, arousal: 0.6, dominance: 0.4}, @ctx)

    {:ok, _} =
      Memory.remember(%{content: "Aria shipped the dashboard journey filter for Priya",
        domain: "product", topic: "dashboard", valence: 0.5, arousal: 0.5, dominance: 0.5}, @ctx)

    {:ok, _} =
      Memory.remember(%{content: "The Postgres deadlock at 2am, debugged with Marcus",
        domain: "debugging", topic: "deadlock", valence: -0.5, arousal: 0.7, dominance: 0.3}, @ctx)

    # inline Oban ran EmbeddingWorker → VectorStore.upsert for each; confirm population
    assert {:ok, n} =
             eventually(fn ->
               case VectorStore.count() do
                 {:ok, c} when c >= 3 -> {:ok, c}
                 _ -> nil
               end
             end)

    assert n >= 3

    # active recall with both Embeddings + Weaviate configured → semantic (named-vector) path
    {:ok, %{results: results}} =
      eventually(fn ->
        case Memory.recall("rust ownership borrow checker lifetimes", [limit: 5], @ctx) do
          {:ok, %{results: r}} = ok -> if Enum.any?(r, &String.contains?(&1.content || "", "Rust")), do: ok, else: nil
          _ -> nil
        end
      end)

    assert Enum.any?(results, &String.contains?(&1.content || "", "Rust")),
           "the Rust memory should surface via the Weaviate content vector"
  end

  test "reinforcement strengthens entries recalled via Weaviate" do
    {:ok, %{id: id}} =
      Memory.remember(%{content: "Aria re-sharded the stitcher during the outage with Theo",
        domain: "incident", topic: "outage", valence: -0.4, arousal: 0.85, dominance: 0.5}, @ctx)

    {:ok, _} =
      Memory.remember(%{content: "Aria reviewed Sam's pull request and left encouraging notes",
        domain: "mentoring", topic: "review", valence: 0.6, arousal: 0.4, dominance: 0.6}, @ctx)

    eventually(fn ->
      case VectorStore.count() do
        {:ok, c} when c >= 2 -> c
        _ -> nil
      end
    end)

    # explicit strengthen / weaken (clamped)
    {:ok, w0} = Memory.denforce(id, @ctx)
    assert w0 < 1.0
    {:ok, w1} = Memory.reinforce(id, @ctx)
    assert w1 > w0

    # a Weaviate-backed recall reinforces the returned set (inline ReinforcementWorker) + Hebbian
    before_co = Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)
    {:ok, %{results: results}} = Memory.recall("the outage stitcher re-shard", [limit: 5], @ctx)
    assert results != []
    assert Enum.any?(results, fn r -> Repo.get(MemSchema, r.id).recall_count >= 1 end)
    after_co = Repo.aggregate(from(e in AssociationEdge, where: e.edge_type == :co_occurrence), :count, :id)
    assert after_co >= before_co
  end
end
