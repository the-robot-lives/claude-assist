defmodule HoloGraph.Docs.DocumentTest do
  use ExUnit.Case, async: true

  alias HoloGraph.Docs.Document

  defp graph_node(attrs) do
    Map.merge(
      %{"id" => "node-a", "label" => "A", "kind" => "class", "description" => "A class."},
      attrs
    )
  end

  defp edge(attrs) do
    Map.merge(
      %{
        "id" => "edge-1",
        "sourceId" => "node-a",
        "targetId" => "node-b",
        "kind" => "calls",
        "label" => "calls"
      },
      attrs
    )
  end

  defp document(attrs) do
    Map.merge(
      %{
        "id" => "trd-demo",
        "slug" => "demo",
        "title" => "Demo",
        "version" => 1,
        "summary" => "Demo doc.",
        "nodes" => [],
        "edges" => []
      },
      attrs
    )
  end

  describe "validate/1" do
    test "accepts a well formed envelope" do
      assert {:ok, %{"id" => "trd-demo"}} = Document.validate(document(%{}))
    end

    test "accepts atom keys and returns string keys" do
      assert {:ok, payload} =
               Document.validate(%{
                 id: "trd-demo",
                 slug: "demo",
                 title: "Demo",
                 version: 1,
                 nodes: [],
                 edges: []
               })

      assert Map.keys(payload) |> Enum.all?(&is_binary/1)
    end

    test "reports every missing or mistyped envelope field" do
      assert {:error, {:invalid_document, reasons}} =
               Document.validate(%{"id" => "trd", "version" => "one"})

      assert "slug must be a string" in reasons
      assert "title must be a string" in reasons
      assert "version must be a number" in reasons
      assert "nodes must be an array" in reasons
      assert "edges must be an array" in reasons
      refute Enum.any?(reasons, &String.starts_with?(&1, "id "))
    end

    test "rejects non-objects" do
      assert {:error, {:invalid_document, _}} = Document.validate("nope")
    end
  end

  describe "normalize/2 — node sanitization" do
    test "drops nodes with an unknown kind" do
      {:ok, payload} =
        document(%{
          "nodes" => [graph_node(%{"id" => "node-a"}), graph_node(%{"id" => "node-x", "kind" => "wormhole"})]
        })
        |> Document.validate_and_normalize()

      assert Enum.map(payload["nodes"], & &1["id"]) == ["node-a"]
    end

    test "de-duplicates node ids from the label" do
      {:ok, payload} =
        document(%{
          "nodes" => [
            graph_node(%{"id" => "node-a", "label" => "Alpha"}),
            graph_node(%{"id" => "node-a", "label" => "Alpha"}),
            graph_node(%{"id" => "node-a", "label" => "Alpha"})
          ]
        })
        |> Document.validate_and_normalize()

      assert Enum.map(payload["nodes"], & &1["id"]) == ["node-a", "node-alpha", "node-alpha-2"]
    end

    test "fills description and metrics defaults" do
      {:ok, payload} =
        document(%{"nodes" => [%{"id" => "node-a", "label" => "Alpha", "kind" => "service"}]})
        |> Document.validate_and_normalize()

      assert [%{"description" => "Alpha UML element.", "metrics" => metrics}] = payload["nodes"]
      assert metrics["complexity"] in 18..60
      assert metrics["churn"] in 8..36
      assert metrics["risk"] in 10..47
    end

    test "preserves opaque node internals" do
      trd3d = %{"position" => %{"x" => 1, "y" => 2, "z" => 3}, "authored" => true}

      {:ok, payload} =
        document(%{"nodes" => [graph_node(%{"trd3d" => trd3d, "stereotype" => "<<entity>>"})]})
        |> Document.validate_and_normalize()

      assert [%{"trd3d" => ^trd3d, "stereotype" => "<<entity>>"}] = payload["nodes"]
    end
  end

  describe "normalize/2 — edge sanitization" do
    test "drops edges with unknown kinds and unresolvable endpoints" do
      nodes = [graph_node(%{"id" => "node-a"}), graph_node(%{"id" => "node-b", "label" => "B"})]

      {:ok, payload} =
        document(%{
          "nodes" => nodes,
          "edges" => [
            edge(%{"id" => "keep"}),
            edge(%{"id" => "bad-kind", "kind" => "teleports"}),
            edge(%{"id" => "dangling-target", "targetId" => "node-ghost"}),
            edge(%{"id" => "dangling-source", "sourceId" => "node-ghost"})
          ]
        })
        |> Document.validate_and_normalize()

      assert Enum.map(payload["edges"], & &1["id"]) == ["keep"]
    end

    test "drops edges whose endpoint node was itself dropped" do
      {:ok, payload} =
        document(%{
          "nodes" => [graph_node(%{"id" => "node-a"}), graph_node(%{"id" => "node-b", "kind" => "wormhole"})],
          "edges" => [edge(%{})]
        })
        |> Document.validate_and_normalize()

      assert payload["edges"] == []
    end

    test "fills id and label defaults positionally" do
      nodes = [graph_node(%{"id" => "node-a"}), graph_node(%{"id" => "node-b", "label" => "B"})]

      {:ok, payload} =
        document(%{
          "nodes" => nodes,
          "edges" => [edge(%{"id" => nil, "label" => nil, "kind" => "depends_on"})]
        })
        |> Document.validate_and_normalize()

      assert [%{"id" => "edge-1", "label" => "depends_on"}] = payload["edges"]
    end
  end

  describe "normalize/2 — envelope defaults" do
    test "fills modelKind, view and updatedAt" do
      {:ok, payload} = Document.validate_and_normalize(document(%{}))

      assert payload["modelKind"] == "uml"
      assert payload["view"] == %{"projection" => "trd-3d-uml", "activeLayer" => 0}
      assert {:ok, _, _} = DateTime.from_iso8601(payload["updatedAt"])
    end

    test "does not clobber a supplied view or modelKind" do
      view = %{"projection" => "class-diagram", "activeLayer" => 2}

      {:ok, payload} =
        Document.validate_and_normalize(document(%{"modelKind" => "sysml", "view" => view}))

      assert payload["modelKind"] == "sysml"
      assert payload["view"] == view
    end
  end

  describe "stamp/3 and summary/1" do
    test "stamp overwrites version and updatedAt" do
      now = ~U[2026-07-27 12:00:00.000Z]
      stamped = Document.stamp(document(%{}), 7, now)

      assert stamped["version"] == 7
      assert stamped["updatedAt"] == "2026-07-27T12:00:00.000Z"
    end

    test "summary counts nodes and edges" do
      nodes = [graph_node(%{"id" => "node-a"}), graph_node(%{"id" => "node-b", "label" => "B"})]
      {:ok, payload} = Document.validate_and_normalize(document(%{"nodes" => nodes}))

      assert %{nodeCount: 2, edgeCount: 0, slug: "demo", title: "Demo"} = Document.summary(payload)
    end
  end

  describe "slugify/1" do
    test "matches the frontend helper" do
      assert Document.slugify("  Payment Service! ") == "payment-service"
      assert Document.slugify("***") == "untitled"
      assert Document.slugify(nil) == "untitled"
    end
  end
end
