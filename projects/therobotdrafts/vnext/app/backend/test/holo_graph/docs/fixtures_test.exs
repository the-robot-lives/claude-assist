defmodule HoloGraph.Docs.FixturesTest do
  use ExUnit.Case, async: true

  alias HoloGraph.Docs.Fixtures
  alias HoloGraph.Docs.GraphDocument

  test "lists legacy fixture-backed document summaries" do
    summaries = Fixtures.list_summaries()
    roadmap = Enum.find(summaries, &(&1.slug == "roadmap-lane-parallelism"))

    assert roadmap
    assert roadmap.lane_count == 3
  end

  test "gets a legacy fixture document by slug" do
    assert {:ok, %GraphDocument{} = document} = Fixtures.get_document("roadmap-lane-parallelism")
    assert document.title == "Roadmap Lane Parallelism"
    assert length(document.nodes) == 4
  end

  test "legacy import echoes caller metadata without persisting" do
    assert {:ok, %GraphDocument{} = document} =
             Fixtures.legacy_import("roadmap-lane-parallelism", %{
               "slug" => "imported-roadmap",
               "metadata" => %{"workspace" => "m0"}
             })

    assert document.slug == "imported-roadmap"
    assert document.metadata["workspace"] == "m0"
    assert document.metadata["imported_from_fixture"] == "roadmap-lane-parallelism"
  end

  test "payload/1 returns raw JSON for the database import path" do
    assert {:ok, payload} = Fixtures.payload("holograph-m0-m1-walking-skeleton")
    assert payload["slug"] == "unity-parity-3d-uml-workspace"
    assert is_list(payload["nodes"])
  end

  test "payload/1 guards the fixture name" do
    assert {:error, :invalid_fixture} = Fixtures.payload("../../etc/passwd")
    assert {:error, :not_found} = Fixtures.payload("no-such-fixture")
  end
end
