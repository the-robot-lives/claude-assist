defmodule HoloGraph.DocsTest do
  use HoloGraph.DataCase, async: false

  alias HoloGraph.Docs
  alias HoloGraph.Schema.Docs.CollabEvent
  alias HoloGraph.Schema.Docs.GraphDocumentVersion

  @moduletag :docs

  setup do
    org =
      Repo.insert!(%HoloGraph.Schema.Organizations.Organization{
        id: Ecto.UUID.generate(),
        slug: "org-#{System.unique_integer([:positive])}",
        name: "Docs Test Org"
      })

    project =
      Repo.insert!(%HoloGraph.Schema.Projects.Project{
        id: Ecto.UUID.generate(),
        organization_id: org.id,
        name: "Docs Test Project",
        slug: "proj-#{System.unique_integer([:positive])}"
      })

    {:ok, org: org, project: project}
  end

  defp payload(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "trd-demo",
        "slug" => "demo-#{System.unique_integer([:positive])}",
        "title" => "Demo Model",
        "version" => 1,
        "summary" => "Walking skeleton.",
        "nodes" => [
          %{"id" => "node-a", "label" => "Alpha", "kind" => "service", "description" => "Alpha."},
          %{"id" => "node-b", "label" => "Beta", "kind" => "class", "description" => "Beta."}
        ],
        "edges" => [
          %{
            "id" => "edge-1",
            "sourceId" => "node-a",
            "targetId" => "node-b",
            "kind" => "calls",
            "label" => "calls"
          }
        ]
      },
      overrides
    )
  end

  defp create_doc(project, overrides \\ %{}) do
    {:ok, document} =
      Docs.create_document(%{
        "project_id" => project.id,
        "organization_id" => project.organization_id,
        "document" => payload(overrides)
      })

    document
  end

  defp batch(operations, overrides \\ %{}) do
    Map.merge(%{"operations" => operations}, overrides)
  end

  defp add_node_op(id \\ "op-1") do
    %{
      "id" => id,
      "type" => "add_node",
      "targetId" => "node-c",
      "label" => "Gamma",
      "status" => "applied"
    }
  end

  describe "create_document/1" do
    test "persists the payload and an initial snapshot", %{project: project} do
      document = create_doc(project)

      assert document.current_version == 1
      assert document.project_id == project.id
      assert document.organization_id == project.organization_id
      assert document.status == "active"
      assert document.title == "Demo Model"

      # envelope is stamped so the jsonb never drifts from the row
      assert document.document["id"] == document.id
      assert document.document["slug"] == document.slug
      assert document.document["version"] == 1

      assert [snapshot] = Repo.all(GraphDocumentVersion)
      assert snapshot.version == 1
      assert snapshot.patch == %{"kind" => "create"}
      assert snapshot.document["id"] == document.id
    end

    test "sanitizes on the way in", %{project: project} do
      document =
        create_doc(project, %{
          "nodes" => [
            %{"id" => "node-a", "label" => "Alpha", "kind" => "service"},
            %{"id" => "node-x", "label" => "Ghost", "kind" => "wormhole"}
          ],
          "edges" => [
            %{"id" => "edge-1", "sourceId" => "node-a", "targetId" => "node-x", "kind" => "calls"}
          ]
        })

      assert Enum.map(document.document["nodes"], & &1["id"]) == ["node-a"]
      assert document.document["edges"] == []
    end

    test "rejects an invalid envelope", %{project: project} do
      assert {:error, {:invalid_document, reasons}} =
               Docs.create_document(%{
                 "project_id" => project.id,
                 "document" => %{"id" => "x", "nodes" => "not-an-array"}
               })

      assert "nodes must be an array" in reasons
    end

    test "de-conflicts a taken slug", %{project: project} do
      first = create_doc(project, %{"slug" => "shared-slug"})
      second = create_doc(project, %{"slug" => "shared-slug"})

      assert first.slug == "shared-slug"
      assert second.slug == "shared-slug-2"
      assert second.document["slug"] == "shared-slug-2"
    end
  end

  describe "get_document/1 and list_by_project/2" do
    test "fetches by uuid and by slug", %{project: project} do
      document = create_doc(project)

      assert {:ok, by_id} = Docs.get_document(document.id)
      assert {:ok, by_slug} = Docs.get_document(document.slug)
      assert by_id.id == document.id
      assert by_slug.id == document.id
      assert {:error, :not_found} = Docs.get_document(Ecto.UUID.generate())
      assert {:error, :not_found} = Docs.get_document("no-such-slug")
    end

    test "lists project summaries and hides deleted docs", %{project: project} do
      kept = create_doc(project)
      dropped = create_doc(project)
      {:ok, _} = Docs.update_document(dropped.id, %{"status" => "deleted", "document" => dropped.document})

      summaries = Docs.list_by_project(project.id)

      assert [%{id: id, nodeCount: 2, edgeCount: 1, version: 1}] = summaries
      assert id == kept.id
    end
  end

  describe "update_document/3 — optimistic locking" do
    test "bumps version, restamps the envelope and snapshots", %{project: project} do
      document = create_doc(project)
      updated_payload = Map.put(document.document, "title", "Renamed")

      assert {:ok, updated} =
               Docs.update_document(document.id, %{"document" => updated_payload, "title" => "Renamed"},
                 expected_version: 1
               )

      assert updated.current_version == 2
      assert updated.title == "Renamed"
      assert updated.document["version"] == 2

      versions = Repo.all(from v in GraphDocumentVersion, order_by: v.version)
      assert Enum.map(versions, & &1.version) == [1, 2]
      assert List.last(versions).patch == %{"kind" => "full_save"}
    end

    test "returns a version conflict when the expected version is stale", %{project: project} do
      document = create_doc(project)
      {:ok, _} = Docs.update_document(document.id, %{"document" => document.document}, expected_version: 1)

      assert {:error, {:version_conflict, details}} =
               Docs.update_document(document.id, %{"document" => document.document},
                 expected_version: 1
               )

      assert details.current_version == 2
      assert details.expected_version == 1
      assert details.document_id == document.id

      # the conflicting save left nothing behind
      assert {:ok, reloaded} = Docs.get_document(document.id)
      assert reloaded.current_version == 2
      assert Repo.aggregate(GraphDocumentVersion, :count) == 2
    end

    test "skips the lock check when no expected version is supplied", %{project: project} do
      document = create_doc(project)
      assert {:ok, updated} = Docs.update_document(document.id, %{"document" => document.document})
      assert updated.current_version == 2
    end

    test "requires a document payload", %{project: project} do
      document = create_doc(project)

      assert {:error, {:invalid_document, ["document is required"]}} =
               Docs.update_document(document.id, %{"title" => "no payload"})
    end

    test "404s for an unknown document" do
      assert {:error, :not_found} =
               Docs.update_document(Ecto.UUID.generate(), %{"document" => payload()})
    end
  end

  describe "apply_patch_batch/3" do
    test "logs the batch verbatim, bumps the version and stores the carried document", %{
      project: project
    } do
      document = create_doc(project)
      next = Map.put(document.document, "summary", "After the patch.")

      assert {:ok, result} =
               Docs.apply_patch_batch(
                 document.id,
                 batch([add_node_op()], %{
                   "client_event_id" => "evt-1",
                   "document" => next,
                   "metadata" => %{"origin" => "autosave"}
                 })
               )

      assert result.version == 2
      refute result.deduplicated?
      refute result.snapshot?
      assert result.document.document["summary"] == "After the patch."
      assert result.document.document["version"] == 2

      assert [event] = Repo.all(CollabEvent)
      assert event.version == 2
      assert event.event_type == "patch_batch"
      assert event.client_event_id == "evt-1"
      assert event.metadata == %{"origin" => "autosave"}
      assert event.patch["operations"] == [add_node_op()]
    end

    test "advances the version without a carried document", %{project: project} do
      document = create_doc(project)

      assert {:ok, result} = Docs.apply_patch_batch(document.id, batch([add_node_op()]))
      assert result.version == 2
      assert result.document.document["nodes"] == document.document["nodes"]
      assert result.document.document["version"] == 2
    end

    test "de-duplicates on client_event_id", %{project: project} do
      document = create_doc(project)
      body = batch([add_node_op()], %{"client_event_id" => "evt-dup"})

      assert {:ok, first} = Docs.apply_patch_batch(document.id, body)
      assert {:ok, replay} = Docs.apply_patch_batch(document.id, body)

      assert first.version == 2
      assert replay.version == 2
      assert replay.deduplicated?
      assert Repo.aggregate(CollabEvent, :count) == 1
      assert {:ok, reloaded} = Docs.get_document(document.id)
      assert reloaded.current_version == 2
    end

    test "batches without a client_event_id are never de-duplicated", %{project: project} do
      document = create_doc(project)

      assert {:ok, _} = Docs.apply_patch_batch(document.id, batch([add_node_op()]))
      assert {:ok, second} = Docs.apply_patch_batch(document.id, batch([add_node_op()]))

      assert second.version == 3
      assert Repo.aggregate(CollabEvent, :count) == 2
    end

    test "honors base_version as an optimistic lock", %{project: project} do
      document = create_doc(project)

      assert {:error, {:version_conflict, details}} =
               Docs.apply_patch_batch(document.id, batch([add_node_op()], %{"base_version" => 9}))

      assert details.current_version == 1
      assert Repo.aggregate(CollabEvent, :count) == 0
    end

    test "snapshots every Nth version", %{project: project} do
      document = create_doc(project)
      every = Docs.snapshot_every()

      results =
        Enum.map(2..every, fn _ ->
          {:ok, result} = Docs.apply_patch_batch(document.id, batch([add_node_op()]))
          result
        end)

      snapshotting = Enum.filter(results, & &1.snapshot?)

      assert Enum.map(snapshotting, & &1.version) == [every]
      assert List.last(results).version == every

      versions = Repo.all(from v in GraphDocumentVersion, order_by: v.version)
      assert Enum.map(versions, & &1.version) == [1, every]
      assert List.last(versions).metadata == %{"reason" => "patch_cadence"}
    end

    test "rejects unknown operation types", %{project: project} do
      document = create_doc(project)

      assert {:error, {:invalid_patch_batch, reasons}} =
               Docs.apply_patch_batch(document.id, batch([%{"id" => "op", "type" => "yeet"}]))

      assert Enum.any?(reasons, &String.contains?(&1, "unsupported operation type"))
    end

    test "rejects a batch whose carried document is malformed", %{project: project} do
      document = create_doc(project)

      assert {:error, {:invalid_patch_batch, reasons}} =
               Docs.apply_patch_batch(
                 document.id,
                 batch([add_node_op()], %{"document" => %{"id" => "x"}})
               )

      assert "nodes must be an array" in reasons
    end
  end

  describe "list_versions/2 and restore_version/3" do
    test "lists newest first without the full payload", %{project: project} do
      document = create_doc(project)
      {:ok, _} = Docs.update_document(document.id, %{"document" => document.document})

      assert {:ok, [latest, first]} = Docs.list_versions(document.id)
      assert latest.version == 2
      assert first.version == 1
      assert latest.nodeCount == 2
      assert latest.edgeCount == 1
      refute Map.has_key?(latest, :document)
    end

    test "restores a snapshot as a new version", %{project: project} do
      document = create_doc(project)
      v1_title = document.document["title"]

      {:ok, v2} =
        Docs.update_document(
          document.id,
          %{"document" => Map.put(document.document, "title", "Second"), "title" => "Second"}
        )

      assert v2.document["title"] == "Second"

      assert {:ok, restored} = Docs.restore_version(document.id, 1)
      assert restored.current_version == 3
      assert restored.document["title"] == v1_title
      assert restored.document["version"] == 3

      assert {:ok, versions} = Docs.list_versions(document.id)
      assert Enum.map(versions, & &1.version) == [3, 2, 1]
      assert hd(versions).metadata == %{"restored_from_version" => 1}
    end

    test "restore accepts a stringified version and 404s on a missing one", %{project: project} do
      document = create_doc(project)

      assert {:ok, restored} = Docs.restore_version(document.id, "1")
      assert restored.current_version == 2
      assert {:error, :not_found} = Docs.restore_version(document.id, 99)
    end
  end

  describe "import_fixture/2" do
    test "persists a canonical GraphDocument fixture", %{project: project} do
      assert {:ok, document} =
               Docs.import_fixture("holograph-m0-m1-walking-skeleton", %{
                 "project_id" => project.id,
                 "organization_id" => project.organization_id
               })

      assert document.project_id == project.id
      assert document.current_version == 1
      assert document.metadata["imported_from_fixture"] == "holograph-m0-m1-walking-skeleton"
      assert length(document.document["nodes"]) == 13
    end

    test "rejects the legacy lanes/kanban fixture" do
      assert {:error, :legacy_fixture} = Docs.import_fixture("roadmap-lane-parallelism")
      assert Repo.aggregate(HoloGraph.Schema.Docs.GraphDocument, :count) == 0
    end

    test "404s for an unknown fixture" do
      assert {:error, :not_found} = Docs.import_fixture("no-such-fixture")
    end
  end
end
