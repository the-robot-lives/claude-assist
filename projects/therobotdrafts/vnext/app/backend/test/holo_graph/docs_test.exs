defmodule HoloGraph.DocsTest do
  use ExUnit.Case, async: true

  alias HoloGraph.Docs
  alias HoloGraph.Docs.GraphDocument

  test "lists fixture-backed document summaries" do
    summaries = Docs.list_summaries()
    roadmap = Enum.find(summaries, &(&1.slug == "roadmap-lane-parallelism"))

    assert roadmap
    assert roadmap.lane_count == 3
  end

  test "gets fixture document by slug" do
    assert {:ok, %GraphDocument{} = document} = Docs.get_document("roadmap-lane-parallelism")
    assert document.title == "Roadmap Lane Parallelism"
    assert length(document.nodes) == 4
  end

  test "imports fixture with caller metadata" do
    assert {:ok, %GraphDocument{} = document} =
             Docs.import_fixture("roadmap-lane-parallelism", %{
               "slug" => "imported-roadmap",
               "metadata" => %{"workspace" => "m0"}
             })

    assert document.slug == "imported-roadmap"
    assert document.metadata["workspace"] == "m0"
    assert document.metadata["imported_from_fixture"] == "roadmap-lane-parallelism"
  end
end
