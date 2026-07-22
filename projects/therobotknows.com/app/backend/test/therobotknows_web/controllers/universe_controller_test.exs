defmodule TherobotknowsWeb.UniverseControllerTest do
  use TherobotknowsWeb.ConnCase

  describe "universes CRUD" do
    test "create list show update delete flow", %{conn: conn} do
      %{access_token: token} = setup_user_and_token()
      conn = authenticated_conn(conn, token)

      # Create
      conn1 =
        post(conn, "/api/v1/universes", %{
          universe: %{
            name: "The Ashward Chronicles",
            slug: "ashward-test-#{System.unique_integer([:positive])}",
            description: "Epic fantasy",
            genre: "Fantasy",
            tone: "grim"
          }
        })

      created = json_response(conn1, 201)["universe"]
      assert created["name"] == "The Ashward Chronicles"
      assert created["role"] == "owner"
      assert created["entry_count"] == 0
      id = created["id"]
      slug = created["slug"]

      # List
      conn2 = get(conn, "/api/v1/universes")
      list = json_response(conn2, 200)
      assert Enum.any?(list["universes"], &(&1["id"] == id))
      assert list["meta"]["total"] >= 1

      # Show by slug
      conn3 = get(conn, "/api/v1/universes/#{slug}")
      shown = json_response(conn3, 200)["universe"]
      assert shown["id"] == id

      # Stats
      conn4 = get(conn, "/api/v1/universes/#{id}/stats")
      stats = json_response(conn4, 200)["stats"]
      assert stats["entry_count"] == 0

      # Update
      conn5 =
        patch(conn, "/api/v1/universes/#{id}", %{
          universe: %{description: "Updated desc", genre: "Dark Fantasy"}
        })

      updated = json_response(conn5, 200)["universe"]
      assert updated["description"] == "Updated desc"
      assert updated["genre"] == "Dark Fantasy"

      # Create entry under universe
      conn6 =
        post(conn, "/api/v1/universes/#{id}/entries", %{
          entry: %{
            type: "character",
            title: "Kael Ashward",
            excerpt: "Master swordsmith",
            body: "A smith of Thornwall.",
            tag_names: ["protagonist"]
          }
        })

      entry = json_response(conn6, 201)["entry"]
      assert entry["type"] == "character"
      assert entry["status"] == "draft"
      assert entry["title"] == "Kael Ashward"
      assert Enum.any?(entry["tags"], &(&1["slug"] == "protagonist"))
      entry_id = entry["id"]

      # List entries
      conn7 = get(conn, "/api/v1/universes/#{id}/entries")
      entries = json_response(conn7, 200)
      assert entries["meta"]["total"] == 1

      # Promote to canon
      conn8 =
        post(conn, "/api/v1/universes/#{id}/entries/#{entry_id}/status", %{status: "canon"})

      promoted = json_response(conn8, 200)["entry"]
      assert promoted["status"] == "canon"

      # Soft-delete universe
      conn9 = delete(conn, "/api/v1/universes/#{id}")
      assert json_response(conn9, 200)["message"] =~ "deleted"

      conn10 = get(conn, "/api/v1/universes/#{id}")
      assert json_response(conn10, 404)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/universes")
      assert conn.status == 401
    end
  end
end
