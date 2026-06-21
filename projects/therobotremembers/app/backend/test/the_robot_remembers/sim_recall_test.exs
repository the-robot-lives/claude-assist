defmodule TheRobotRemembers.SimRecallTest do
  @moduledoc """
  Loads the hand-authored year-long simulated corpus (`sim/memory/aria/**`) via `SimLoader` and
  asserts recall over it: emotional resonance, lexical/topic, preference/feeling, collaborator
  threads, the association graph, agent binding, and round-trip richness. Embeddings/Weaviate are
  forced off in tests (see test_helper), so recall uses the pg_trgm lexical fallback + pgvector
  emotional path; `Oban testing: :inline` makes load build the Weaver graph synchronously.
  """
  use TheRobotRemembers.DataCase, async: false

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.Memory.SimLoader
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema
  alias TheRobotRemembers.Schema.Memory.AssociationEdge

  @agent "aria"
  @ctx %{owner_agent: @agent, requester_id: @agent}
  @moduletag timeout: 600_000

  defp any_text?(results, sub) do
    s = String.downcase(sub)

    Enum.any?(results, fn r ->
      String.contains?(String.downcase("#{r.content} #{r.context} #{r.topic}"), s)
    end)
  end

  test "loads the year corpus and recalls across emotion, content, people, preferences, and graph" do
    r = SimLoader.load(@agent)
    assert r.files >= 30, "expected the full year of day-files (got #{r.files})"
    assert r.ok >= 150, "expected the full corpus archived (got #{r.ok})"
    assert r.quarantined == 0

    rows = Repo.all(from m in MemSchema, where: m.owner_agent == @agent)
    assert length(rows) == r.ok
    assert Enum.all?(rows, &(&1.state == :active)), "inline embedding worker activates each memory"

    # the lived year: moods span, domains + people vary
    vals = Enum.map(rows, & &1.valence)
    assert Enum.min(vals) < -0.3 and Enum.max(vals) > 0.5
    assert rows |> Enum.map(& &1.domain) |> Enum.uniq() |> length() >= 8
    collabs = rows |> Enum.flat_map(&(&1.collaborators || [])) |> Enum.uniq()
    assert "marcus" in collabs and "theo" in collabs and "sam" in collabs

    # ── emotional resonance ──
    {:ok, %{results: stressed}} =
      Memory.recall_by_emotion(%{mood: %{valence: -0.55, arousal: 0.9, dominance: 0.4}}, [limit: 10], @ctx)

    assert Enum.count(stressed, &(&1.valence < 0)) >= 6, "a stressed state should surface mostly negative memories"
    res = Enum.map(stressed, & &1.resonance)
    assert res == Enum.sort(res, :desc)

    {:ok, %{results: calm}} =
      Memory.recall_by_emotion(%{mood: %{valence: 0.6, arousal: 0.3, dominance: 0.78}}, [limit: 10], @ctx)

    assert Enum.count(calm, &(&1.valence > 0)) >= 6, "a calm-positive state should surface mostly positive memories"

    # ── lexical / topic recall over the whole year ──
    {:ok, %{results: nw}} = Memory.recall("Northwind enterprise customer", [limit: 20], @ctx)
    assert any_text?(nw, "northwind")

    {:ok, %{results: outage}} = Memory.recall("the outage when the stitcher melted", [limit: 20], @ctx)
    assert any_text?(outage, "outage") or any_text?(outage, "stitcher")

    {:ok, %{results: rust}} = Memory.recall("the Rust ingestion rewrite", [limit: 20], @ctx)
    assert any_text?(rust, "rust")

    # ── preference / feeling recall (the new dimension) ──
    prefs = Repo.all(from m in MemSchema, where: m.owner_agent == @agent and m.domain == "preference")
    assert length(prefs) >= 10, "preference/feeling memories are present"

    {:ok, %{results: java}} = Memory.recall("enterprise Java too wordy", [limit: 20], @ctx)
    assert any_text?(java, "java")

    {:ok, %{results: music}} = Memory.recall("favorite music playlist", [limit: 20], @ctx)
    assert any_text?(music, "music")

    # ── collaborator threads ──
    assert Enum.count(rows, &("marcus" in (&1.collaborators || []))) >= 20
    {:ok, %{results: marcus}} = Memory.recall("Marcus mentorship code review", [limit: 10], @ctx)
    assert marcus != []

    # ── association graph (Weaver built it during load) ──
    edge_types =
      Repo.all(from e in AssociationEdge, group_by: e.edge_type, select: {e.edge_type, count(e.id)})
      |> Map.new()

    assert Map.get(edge_types, :emotional, 0) > 0
    assert Map.get(edge_types, :contextual, 0) > 0

    # ── agent binding: a different owner sees nothing ──
    {:ok, %{results: ghost}} =
      Memory.recall_by_emotion(%{mood: %{valence: 0.0, arousal: 0.5, dominance: 0.5}}, [limit: 20],
        %{owner_agent: "ghost", requester_id: "ghost"})

    assert ghost == []

    # ── paragraph-length context survives the round-trip ──
    assert Enum.any?(rows, &(String.length(&1.context || "") > 200))
  end
end
