defmodule TimelyWeb.TimelySyncApiTest do
  @moduledoc """
  The HTTP surface, asserted against `apps/shared/contracts/timely-api.yaml`.

  These go through the real router and the real Guardian bearer pipeline, so
  they cover the things a context-level test cannot: that the routes exist, that
  they are actually authenticated, that status codes match the contract, and
  that a caller cannot reach a workspace they do not belong to.
  """
  use TimelyWeb.ConnCase, async: false
  use TimelyWeb, :verified_routes

  import Ecto.Query
  import Timely.TimelyFixtures

  alias Timely.Sync.Blobs
  alias Timely.Sync.Canon

  setup %{conn: conn} do
    Blobs.Memory.reset()

    %{user: user, access_token: token} = setup_user_and_token()
    workspace_id = workspace!()
    member!(user.id, workspace_id, "owner")

    {:ok,
     conn: authenticated_conn(conn, token),
     anon_conn: Phoenix.ConnTest.build_conn(),
     user: user,
     workspace_id: workspace_id}
  end

  defp span_payload(overrides) do
    Map.merge(
      %{
        "id" => uuid7(),
        "title" => "Timeline canvas",
        "start" => iso(-3600),
        "end" => iso(-60),
        "source" => "timer",
        "is_billable" => false,
        "updated_at" => iso(-60)
      },
      overrides
    )
  end

  defp register_device(conn, workspace_id, overrides) do
    body =
      Map.merge(
        %{
          "device_id" => uuid7(),
          "workspace_id" => workspace_id,
          "platform" => "macos",
          "name" => "Keith's MacBook Pro",
          "app_version" => "1.0.0"
        },
        overrides
      )

    post(conn, ~p"/api/v1/devices", body)
  end

  describe "authentication" do
    test "every Timely route requires a bearer token", %{
      anon_conn: conn,
      workspace_id: workspace_id
    } do
      assert json_response(get(conn, ~p"/api/v1/sync/changes?workspace_id=#{workspace_id}&since=0"), 401)
      assert json_response(post(conn, ~p"/api/v1/devices", %{}), 401)
      assert json_response(post(conn, ~p"/api/v1/sync/mutations", %{}), 401)

      assert json_response(
               get(conn, ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&from=#{iso(-3600)}&to=#{iso()}"),
               401
             )
    end

    test "a member of another workspace is refused with 403", %{conn: conn} do
      # Deliberately indistinguishable from "no such workspace": a non-member
      # must not be able to probe which workspace ids exist.
      other = workspace!()

      response =
        conn
        |> get(~p"/api/v1/sync/changes?workspace_id=#{other}&since=0")
        |> json_response(403)

      assert response["code"] == "forbidden"
    end

    test "a missing workspace_id is a 400", %{conn: conn} do
      assert json_response(get(conn, ~p"/api/v1/sync/changes?since=0"), 400)
    end
  end

  describe "POST /api/v1/devices" do
    test "registers a device and returns a DeviceEnvelope", %{
      conn: conn,
      workspace_id: workspace_id,
      user: user
    } do
      device_id = uuid7()
      response = register_device(conn, workspace_id, %{"device_id" => device_id})
      body = json_response(response, 200)

      assert body["device"]["id"] == device_id
      assert body["device"]["user_id"] == user.id
      assert body["device"]["platform"] == "macos"
      # The privacy-preserving default.
      assert body["device"]["local_only_screenshots"] == true

      assert body["workspace_policy"]["kind"] == "workspace_policy"
      assert body["workspace_policy"]["screenshot_upload_allowed"] == false
      assert is_binary(body["server_time"])
      assert is_integer(body["sync_cursor"])
    end

    test "is idempotent by client-supplied device_id", %{conn: conn, workspace_id: workspace_id} do
      device_id = uuid7()

      first = json_response(register_device(conn, workspace_id, %{"device_id" => device_id}), 200)

      second =
        json_response(
          register_device(conn, workspace_id, %{"device_id" => device_id, "name" => "Renamed"}),
          200
        )

      # The same row, so origin_device_id history stays intact across reinstall.
      assert second["device"]["id"] == first["device"]["id"]
      assert second["device"]["created_at"] == first["device"]["created_at"]
      assert second["device"]["name"] == "Renamed"
    end

    test "refuses a capture-agent claim from a companion platform", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      response =
        register_device(conn, workspace_id, %{
          "platform" => "android",
          "is_capture_agent" => true
        })

      # Only macOS captures. A companion claiming otherwise is lying about what
      # the install is, not stating a preference.
      assert json_response(response, 400)["code"] == "validation_failed"
    end

    test "rejects a non-uuid device_id", %{conn: conn, workspace_id: workspace_id} do
      response = register_device(conn, workspace_id, %{"device_id" => "nope"})
      assert json_response(response, 400)["code"] == "validation_failed"
    end
  end

  describe "PATCH /api/v1/devices/{device_id}" do
    test "updates the caller's own device", %{conn: conn, workspace_id: workspace_id} do
      device_id = uuid7()
      register_device(conn, workspace_id, %{"device_id" => device_id})

      body =
        conn
        |> patch(~p"/api/v1/devices/#{device_id}", %{
          "name" => "Studio Mac",
          "local_only_screenshots" => false
        })
        |> json_response(200)

      assert body["device"]["name"] == "Studio Mac"
      assert body["device"]["local_only_screenshots"] == false
    end

    test "refuses another user's device with 403", %{conn: conn, workspace_id: workspace_id} do
      colleague = user!()
      member!(colleague.id, workspace_id, "member")
      theirs = device!(workspace_id, colleague.id, platform: "ios")

      response = patch(conn, ~p"/api/v1/devices/#{theirs.id}", %{"name" => "hijacked"})

      assert json_response(response, 403)["code"] == "not_device_owner"
    end

    test "answers 404 for an unknown device", %{conn: conn} do
      body = json_response(patch(conn, ~p"/api/v1/devices/#{uuid7()}", %{"name" => "x"}), 404)
      assert body["code"] == "not_found"
    end

    test "answers 404 for a non-uuid device id rather than raising", %{conn: conn} do
      assert json_response(patch(conn, ~p"/api/v1/devices/nope", %{"name" => "x"}), 404)
    end
  end

  describe "GET /api/v1/sync/changes" do
    test "returns a ChangesResponse with every bucket present", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      span!(workspace_id, title: "One")

      body =
        conn
        |> get(~p"/api/v1/sync/changes?workspace_id=#{workspace_id}&since=0")
        |> json_response(200)

      assert length(body["changes"]["time_spans"]) == 1
      assert body["changes"]["screenshots"] == []
      assert is_integer(body["next_cursor"])
      assert is_boolean(body["has_more"])
      assert is_integer(body["tombstone_horizon_revision"])
      assert is_binary(body["server_time"])
    end

    test "honours limit and reports has_more", %{conn: conn, workspace_id: workspace_id} do
      for n <- 1..4, do: span!(workspace_id, title: "Span #{n}")

      body =
        conn
        |> get(~p"/api/v1/sync/changes?workspace_id=#{workspace_id}&since=0&limit=2")
        |> json_response(200)

      assert length(body["changes"]["time_spans"]) == 2
      assert body["has_more"] == true
    end

    test "answers 410 when the cursor predates the tombstone horizon", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      span!(workspace_id)

      Timely.Repo.update_all(
        Timely.Schema.Sync.WorkspaceRevision
        |> where(workspace_id: ^workspace_id),
        set: [current_revision: 100, tombstone_horizon_revision: 100]
      )

      body =
        conn
        |> get(~p"/api/v1/sync/changes?workspace_id=#{workspace_id}&since=5")
        |> json_response(410)

      assert body["code"] == "cursor_too_old"
      assert body["details"]["tombstone_horizon_revision"] == 100
    end

    test "renders a time span in the contract's wire shape", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      span!(workspace_id, title: "Wire shape")

      [row] =
        conn
        |> get(~p"/api/v1/sync/changes?workspace_id=#{workspace_id}&since=0&entities=time_spans")
        |> json_response(200)
        |> get_in(["changes", "time_spans"])

      # `start` and `end` on the wire; start_at / end_at only in SQL.
      assert Map.has_key?(row, "start")
      refute Map.has_key?(row, "start_at")

      for field <- ~w(id workspace_id created_at updated_at server_revision deleted_at
                      origin_device_id title source is_billable notes review_state
                      review_reasons updated_at_effective) do
        assert Map.has_key?(row, field), "missing required field #{field}"
      end
    end
  end

  describe "POST /api/v1/sync/mutations" do
    test "returns 200 with per-mutation results", %{conn: conn, workspace_id: workspace_id} do
      id = uuid7()

      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "mutations" => [
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "create",
              "payload" => span_payload(%{"id" => id})
            }
          ]
        })
        |> json_response(200)

      assert [result] = body["results"]
      assert result["status"] == "applied"
      assert result["entity"]["id"] == id
      # The discriminator: results arrive in one flat array, so the kind has to
      # be on the wire rather than inferred from the row's field shape.
      assert result["entity_kind"] == "time_span"
      assert result["replayed"] == false
      assert result["side_effects"] == []
      assert result["unresolved_refs"] == []
      assert is_integer(body["next_cursor"])
      assert is_binary(body["server_time"])
    end

    test "a 200 does not mean every mutation succeeded", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "mutations" => [
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "create",
              "payload" => span_payload(%{})
            },
            %{
              "mutation_id" => uuid7(),
              "entity" => "wormhole",
              "op" => "create",
              "payload" => %{"id" => uuid7()}
            }
          ]
        })
        |> json_response(200)

      assert Enum.map(body["results"], & &1["status"]) == ["applied", "rejected"]
      # Mixed-kind batches are the case the discriminator exists for.
      assert Enum.map(body["results"], & &1["entity_kind"]) == ["time_span", nil]
    end

    test "a mixed-kind batch tags each result over the wire", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "mutations" => [
            %{
              "mutation_id" => uuid7(),
              "entity" => "client",
              "op" => "create",
              "payload" => %{
                "id" => Canon.client_id(workspace_id, "Acme"),
                "name" => "Acme",
                "updated_at" => iso()
              }
            },
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "create",
              "payload" => span_payload(%{})
            }
          ]
        })
        |> json_response(200)

      assert Enum.map(body["results"], & &1["entity_kind"]) == ["client", "time_span"]

      for result <- body["results"] do
        assert result["entity_kind"] in ~w(client project ticket time_span screenshot
                                           vision_analysis censored_screenshot device
                                           user_settings workspace_policy)
      end
    end

    test "an atomic batch that cannot be applied in full answers 409", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      locked = span!(workspace_id, locked_at: DateTime.utc_now())
      good_id = uuid7()

      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "atomic" => true,
          "mutations" => [
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "create",
              "payload" => span_payload(%{"id" => good_id})
            },
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "update",
              "payload" => span_payload(%{"id" => locked.id, "updated_at" => iso()})
            }
          ]
        })
        |> json_response(409)

      assert Enum.all?(body["results"], &(&1["reason"] == "batch_rolled_back"))
      assert Timely.Sync.Workspace.fetch_live(Timely.Schema.Tracking.TimeSpan, workspace_id, good_id) == nil
    end

    test "an oversized batch answers 413", %{conn: conn, workspace_id: workspace_id} do
      mutations =
        for _ <- 1..201 do
          %{
            "mutation_id" => uuid7(),
            "entity" => "time_span",
            "op" => "create",
            "payload" => span_payload(%{})
          }
        end

      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "mutations" => mutations
        })
        |> json_response(413)

      assert body["code"] == "payload_too_large"
    end

    test "a replay is answered from the ledger", %{conn: conn, workspace_id: workspace_id} do
      mutation_id = uuid7()

      payload = %{
        "workspace_id" => workspace_id,
        "device_id" => uuid7(),
        "mutations" => [
          %{
            "mutation_id" => mutation_id,
            "entity" => "time_span",
            "op" => "create",
            "payload" => span_payload(%{})
          }
        ]
      }

      first = json_response(post(conn, ~p"/api/v1/sync/mutations", payload), 200)
      second = json_response(post(conn, ~p"/api/v1/sync/mutations", payload), 200)

      assert hd(first["results"])["replayed"] == false
      assert hd(second["results"])["replayed"] == true
      assert hd(second["results"])["entity"]["server_revision"] ==
               hd(first["results"])["entity"]["server_revision"]
    end

    test "auto-vivified taxonomy comes back as side effects", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      body =
        conn
        |> post(~p"/api/v1/sync/mutations", %{
          "workspace_id" => workspace_id,
          "device_id" => uuid7(),
          "mutations" => [
            %{
              "mutation_id" => uuid7(),
              "entity" => "time_span",
              "op" => "create",
              "payload" =>
                span_payload(%{"client_name" => "Acme", "project_name" => "Redesign"})
            }
          ]
        })
        |> json_response(200)

      [result] = body["results"]
      effects = Map.new(result["side_effects"], &{&1["entity"], &1["row"]})

      # Returned inline so the pushing client can render a project name without
      # waiting for the next pull.
      assert effects["client"]["id"] == Canon.client_id(workspace_id, "Acme")
      assert effects["project"]["id"] == Canon.project_id(workspace_id, "Acme", "Redesign")
      assert effects["client"]["auto_created"] == true
    end
  end

  describe "screenshot blobs" do
    test "GET answers 404 for a local-only screenshot, which is the normal path", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      screenshot = screenshot!(workspace_id)

      body =
        conn
        |> get(~p"/api/v1/screenshots/#{screenshot.id}/blob")
        |> json_response(404)

      assert body["code"] == "blob_not_available"
    end

    test "POST answers 409 with a gates object when the double gate is closed", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      device_id = uuid7()
      register_device(conn, workspace_id, %{"device_id" => device_id})
      screenshot = screenshot!(workspace_id)

      body =
        conn
        |> put_req_header("x-timely-device-id", device_id)
        |> put_req_header("content-type", "image/png")
        |> post(~p"/api/v1/screenshots/#{screenshot.id}/blob", "PNGBYTES")
        |> json_response(409)

      assert body["code"] == "blob_upload_forbidden"
      assert body["gates"]["workspace_upload_allowed"] == false
      assert body["gates"]["device_local_only"] == true
    end

    test "POST stores the bytes once both gates are open, and GET returns them", %{
      conn: conn,
      workspace_id: workspace_id
    } do
      device_id = uuid7()
      register_device(conn, workspace_id, %{"device_id" => device_id})
      set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})

      patch(conn, ~p"/api/v1/devices/#{device_id}", %{"local_only_screenshots" => false})

      screenshot = screenshot!(workspace_id)

      created =
        conn
        |> put_req_header("x-timely-device-id", device_id)
        |> put_req_header("content-type", "image/png")
        |> post(~p"/api/v1/screenshots/#{screenshot.id}/blob", "PNGBYTES")
        |> json_response(201)

      assert created["upload_state"] == "uploaded"
      assert created["blob_byte_size"] == byte_size("PNGBYTES")
      assert is_integer(created["server_revision"])

      download = get(conn, ~p"/api/v1/screenshots/#{screenshot.id}/blob")
      assert download.status == 200
      assert download.resp_body == "PNGBYTES"
    end

    test "POST without the device header is a 400", %{conn: conn, workspace_id: workspace_id} do
      screenshot = screenshot!(workspace_id)

      body =
        conn
        |> put_req_header("content-type", "image/png")
        |> post(~p"/api/v1/screenshots/#{screenshot.id}/blob", "PNGBYTES")
        |> json_response(400)

      assert body["code"] == "validation_failed"
    end

    test "a screenshot in another workspace is not reachable", %{conn: conn} do
      other = workspace!()
      theirs = screenshot!(other)

      # The workspace is derived from the row, and membership is then checked
      # against it - so a non-member gets 403, never the bytes.
      assert json_response(get(conn, ~p"/api/v1/screenshots/#{theirs.id}/blob"), 403)
    end
  end

  describe "GET /api/v1/reports/summary" do
    test "returns a ReportSummary", %{conn: conn, workspace_id: workspace_id} do
      base = DateTime.utc_now() |> DateTime.add(-7200, :second)

      span!(workspace_id,
        start_at: base,
        end_at: DateTime.add(base, 3600, :second),
        is_billable: true,
        project_name: "Redesign",
        project_id: Ecto.UUID.generate()
      )

      body =
        conn
        |> get(
          ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&from=#{iso(-10_800)}&to=#{iso(3600)}"
        )
        |> json_response(200)

      assert body["totals"]["elapsed_seconds"] == 3600
      assert body["totals"]["billable_seconds"] == 3600
      assert body["totals"]["weighted_billable_seconds"] == 3600
      assert body["group_by"] == "project"
      assert [group] = body["groups"]
      assert group["label"] == "Redesign"
    end

    test "rejects a missing or malformed range", %{conn: conn, workspace_id: workspace_id} do
      assert json_response(
               get(conn, ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&to=#{iso()}"),
               400
             )

      assert json_response(
               get(
                 conn,
                 ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&from=yesterday&to=#{iso()}"
               ),
               400
             )
    end

    test "rejects an inverted range", %{conn: conn, workspace_id: workspace_id} do
      body =
        conn
        |> get(
          ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&from=#{iso()}&to=#{iso(-3600)}"
        )
        |> json_response(400)

      assert body["message"] =~ "after"
    end

    test "rejects an unknown group_by", %{conn: conn, workspace_id: workspace_id} do
      assert json_response(
               get(
                 conn,
                 ~p"/api/v1/reports/summary?workspace_id=#{workspace_id}&from=#{iso(-3600)}&to=#{iso()}&group_by=phase_of_moon"
               ),
               400
             )
    end
  end
end
