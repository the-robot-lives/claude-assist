defmodule HoloGraphWeb.DocsControllerTest do
  use HoloGraphWeb.ConnCase, async: false

  alias HoloGraph.Docs
  alias HoloGraph.Projects
  alias HoloGraph.Repo

  @moduletag :docs

  setup %{conn: conn} do
    owner = setup_user_and_token()
    outsider = setup_user_and_token()

    org =
      Repo.insert!(%HoloGraph.Schema.Organizations.Organization{
        id: Ecto.UUID.generate(),
        slug: "org-#{System.unique_integer([:positive])}",
        name: "Docs Controller Org"
      })

    {:ok, project} =
      Projects.create_with_owner(
        %{
          organization_id: org.id,
          name: "Docs Controller Project",
          slug: "proj-#{System.unique_integer([:positive])}"
        },
        owner.user.id
      )

    {:ok,
     conn: conn,
     owner: owner,
     outsider: outsider,
     org: org,
     project: project,
     owner_conn: authenticated_conn(conn, owner.access_token),
     outsider_conn: authenticated_conn(conn, outsider.access_token)}
  end

  defp payload(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "trd-demo",
        "slug" => "controller-demo-#{System.unique_integer([:positive])}",
        "title" => "Controller Demo",
        "version" => 1,
        "summary" => "Controller demo model.",
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

  defp json_request(conn, method, path, body) do
    conn
    |> put_req_header("content-type", "application/json")
    |> then(fn conn ->
      case method do
        :post -> post(conn, path, Jason.encode!(body))
        :put -> put(conn, path, Jason.encode!(body))
      end
    end)
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

  describe "POST /api/v1/projects/:project_id/docs" do
    test "creates a document for a project member", %{owner_conn: conn, project: project} do
      conn =
        json_request(conn, :post, "/api/v1/projects/#{project.id}/docs", %{
          "document" => payload(%{"slug" => "created-by-controller"})
        })

      assert %{"data" => document, "meta" => meta} = json_response(conn, 201)
      assert document["slug"] == "created-by-controller"
      assert document["version"] == 1
      assert meta["source"] == "database"
      assert meta["projectId"] == project.id
      assert meta["currentVersion"] == 1
    end

    test "422s on an invalid envelope", %{owner_conn: conn, project: project} do
      conn =
        json_request(conn, :post, "/api/v1/projects/#{project.id}/docs", %{
          "document" => %{"id" => "x", "slug" => "y", "title" => "z", "version" => 1}
        })

      assert %{"error" => %{"code" => "invalid_document", "details" => details}} =
               json_response(conn, 422)

      assert "nodes must be an array" in details
    end

    test "403s for a non-member", %{outsider_conn: conn, project: project} do
      conn =
        json_request(conn, :post, "/api/v1/projects/#{project.id}/docs", %{
          "document" => payload()
        })

      assert %{"error" => %{"code" => "forbidden"}} = json_response(conn, 403)
    end

    test "401s without a token", %{conn: conn, project: project} do
      conn = json_request(conn, :post, "/api/v1/projects/#{project.id}/docs", %{})
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/v1/projects/:project_id/docs" do
    test "lists summaries for a member", %{owner_conn: conn, project: project} do
      document = create_doc(project)
      conn = get(conn, "/api/v1/projects/#{project.id}/docs")

      assert %{"data" => [summary]} = json_response(conn, 200)
      assert summary["id"] == document.id
      assert summary["nodeCount"] == 2
      assert summary["edgeCount"] == 1
    end

    test "403s for a non-member", %{outsider_conn: conn, project: project} do
      conn = get(conn, "/api/v1/projects/#{project.id}/docs")
      assert json_response(conn, 403)
    end
  end

  describe "GET /api/v1/docs/:id" do
    test "returns the full document", %{owner_conn: conn, project: project} do
      document = create_doc(project)
      conn = get(conn, "/api/v1/docs/#{document.id}")

      assert %{"data" => data, "meta" => meta} = json_response(conn, 200)
      assert data["id"] == document.id
      assert length(data["nodes"]) == 2
      assert meta["currentVersion"] == 1
    end

    test "404s for an unknown document", %{owner_conn: conn} do
      conn = get(conn, "/api/v1/docs/#{Ecto.UUID.generate()}")
      assert %{"error" => %{"code" => "not_found"}} = json_response(conn, 404)
    end

    test "403s for a user outside the project", %{outsider_conn: conn, project: project} do
      document = create_doc(project)
      conn = get(conn, "/api/v1/docs/#{document.id}")
      assert json_response(conn, 403)
    end
  end

  describe "PUT /api/v1/docs/:id" do
    test "saves a new version", %{owner_conn: conn, project: project} do
      document = create_doc(project)
      updated = Map.put(document.document, "summary", "Saved from the controller.")

      conn = json_request(conn, :put, "/api/v1/docs/#{document.id}", %{"document" => updated})

      assert %{"data" => data, "meta" => meta} = json_response(conn, 200)
      assert data["summary"] == "Saved from the controller."
      assert data["version"] == 2
      assert meta["currentVersion"] == 2
    end

    test "409s when the payload version is stale", %{owner_conn: conn, project: project} do
      document = create_doc(project)
      {:ok, _} = Docs.update_document(document.id, %{"document" => document.document})

      conn = json_request(conn, :put, "/api/v1/docs/#{document.id}", %{"document" => document.document})

      assert %{"error" => error} = json_response(conn, 409)
      assert error["code"] == "version_conflict"
      assert error["current_version"] == 2
      assert error["expected_version"] == 1
    end

    test "403s for a non-member", %{outsider_conn: conn, project: project} do
      document = create_doc(project)
      conn = json_request(conn, :put, "/api/v1/docs/#{document.id}", %{"document" => document.document})
      assert json_response(conn, 403)
    end
  end

  describe "POST /api/v1/docs/:id/patches" do
    test "applies and then de-duplicates a batch", %{owner_conn: conn, project: project} do
      document = create_doc(project)

      body = %{
        "client_event_id" => "evt-controller-1",
        "operations" => [
          %{
            "id" => "op-1",
            "type" => "rename",
            "targetId" => "node-a",
            "label" => "Alpha Prime",
            "status" => "applied"
          }
        ]
      }

      applied =
        conn
        |> json_request(:post, "/api/v1/docs/#{document.id}/patches", body)
        |> json_response(200)

      assert applied["data"]["status"] == "applied"
      assert applied["data"]["version"] == 2
      assert applied["data"]["clientEventId"] == "evt-controller-1"
      assert applied["data"]["snapshot"] == false

      replayed =
        conn
        |> json_request(:post, "/api/v1/docs/#{document.id}/patches", body)
        |> json_response(200)

      assert replayed["data"]["status"] == "deduplicated"
      assert replayed["data"]["version"] == 2
    end

    test "422s on an unsupported operation", %{owner_conn: conn, project: project} do
      document = create_doc(project)

      conn =
        json_request(conn, :post, "/api/v1/docs/#{document.id}/patches", %{
          "operations" => [%{"id" => "op", "type" => "yeet"}]
        })

      assert %{"error" => %{"code" => "invalid_patch_batch"}} = json_response(conn, 422)
    end

    test "403s for a non-member", %{outsider_conn: conn, project: project} do
      document = create_doc(project)

      conn =
        json_request(conn, :post, "/api/v1/docs/#{document.id}/patches", %{"operations" => []})

      assert json_response(conn, 403)
    end
  end

  describe "versions" do
    test "lists and restores", %{owner_conn: conn, project: project} do
      document = create_doc(project)

      {:ok, _} =
        Docs.update_document(document.id, %{
          "document" => Map.put(document.document, "title", "Second")
        })

      listing = conn |> get("/api/v1/docs/#{document.id}/versions") |> json_response(200)
      assert Enum.map(listing["data"], & &1["version"]) == [2, 1]

      restored =
        conn
        |> post("/api/v1/docs/#{document.id}/versions/1/restore")
        |> json_response(200)

      assert restored["data"]["title"] == "Controller Demo"
      assert restored["data"]["version"] == 3
    end

    test "403s for a non-member", %{outsider_conn: conn, project: project} do
      document = create_doc(project)
      assert conn |> get("/api/v1/docs/#{document.id}/versions") |> json_response(403)
    end
  end

  describe "fixture routes" do
    test "the legacy fixture index and show still work", %{conn: conn} do
      listing = conn |> get("/api/v1/holograph/docs") |> json_response(200)
      assert listing["meta"]["source"] == "fixture"

      assert Enum.any?(listing["data"], &(&1["slug"] == "roadmap-lane-parallelism"))

      document =
        conn |> get("/api/v1/holograph/docs/roadmap-lane-parallelism") |> json_response(200)

      assert document["data"]["title"] == "Roadmap Lane Parallelism"
    end

    test "fixture import is admin gated", %{owner_conn: conn} do
      conn =
        json_request(conn, :post, "/api/v1/holograph/docs/import", %{
          "fixture" => "holograph-m0-m1-walking-skeleton"
        })

      assert json_response(conn, 403)
    end

    test "an admin can import a canonical fixture into a project", %{
      conn: conn,
      owner: owner,
      project: project
    } do
      Repo.get!(HoloGraph.Schema.Users.User, owner.user.id)
      |> Ecto.Changeset.change(%{admin: true})
      |> Repo.update!()

      admin_conn = authenticated_conn(conn, owner.access_token)

      response =
        admin_conn
        |> json_request(:post, "/api/v1/holograph/docs/import", %{
          "fixture" => "holograph-m0-m1-walking-skeleton",
          "project_id" => project.id,
          "organization_id" => project.organization_id
        })
        |> json_response(201)

      assert response["meta"]["imported"] == true
      assert response["meta"]["projectId"] == project.id
      assert length(response["data"]["nodes"]) == 13
    end

    test "a legacy lanes fixture is echoed back unpersisted", %{conn: conn, owner: owner} do
      Repo.get!(HoloGraph.Schema.Users.User, owner.user.id)
      |> Ecto.Changeset.change(%{admin: true})
      |> Repo.update!()

      response =
        conn
        |> authenticated_conn(owner.access_token)
        |> json_request(:post, "/api/v1/holograph/docs/import", %{
          "fixture" => "roadmap-lane-parallelism"
        })
        |> json_response(201)

      assert response["meta"]["persisted"] == false
      assert response["data"]["title"] == "Roadmap Lane Parallelism"
      assert Repo.aggregate(HoloGraph.Schema.Docs.GraphDocument, :count) == 0
    end
  end
end
