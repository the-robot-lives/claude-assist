defmodule CodefreshWeb.OrganizationControllerTest do
  use CodefreshWeb.ConnCase

  describe "organizations" do
    test "create and list organizations", %{conn: conn} do
      %{access_token: token} = setup_user_and_token()
      auth_conn = authenticated_conn(conn, token)

      # Create org
      slug = "test-org-#{System.unique_integer([:positive])}"

      conn1 =
        post(auth_conn, "/api/v1/organizations", %{
          organization: %{slug: slug, name: "Test Org"}
        })

      assert json_response(conn1, 201)["organization"]["name"] == "Test Org"

      # List orgs
      conn2 = get(auth_conn, "/api/v1/organizations")
      orgs = json_response(conn2, 200)["organizations"]
      assert length(orgs) >= 1
    end

    test "M0 org invite and API-token lifecycle works end-to-end", %{conn: conn} do
      %{access_token: access_token} = setup_user_and_token()
      auth_conn = authenticated_conn(conn, access_token)

      slug = "m0-flow-#{System.unique_integer([:positive])}"

      create_org_conn =
        post(auth_conn, "/api/v1/organizations", %{
          organization: %{slug: slug, name: "M0 Flow Org"}
        })

      org = json_response(create_org_conn, 201)["organization"]
      org_id = org["id"]

      invite_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> post("/api/v1/organizations/#{org_id}/invites", %{
          invite: %{
            email: "invitee-#{System.unique_integer([:positive])}@example.com",
            role: "viewer"
          }
        })

      invite_response = json_response(invite_conn, 201)
      invite = invite_response["invite"]
      assert invite["role"] == "viewer"
      assert invite_response["raw_token"]

      revoke_invite_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> delete("/api/v1/organizations/#{org_id}/invites/#{invite["id"]}")

      assert response(revoke_invite_conn, 204) == ""

      token_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> post("/api/v1/organizations/#{org_id}/api-tokens", %{
          token: %{name: "ci-token", role: "ci"}
        })

      token_response = json_response(token_conn, 201)
      api_token = token_response["token"]
      raw_token = token_response["raw_token"]

      assert api_token["role"] == "ci"
      assert api_token["key_prefix"] == String.slice(raw_token, 0, 8)
      refute Map.has_key?(api_token, "token_hash")

      list_tokens_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> get("/api/v1/organizations/#{org_id}/api-tokens")

      [listed_token | _] = json_response(list_tokens_conn, 200)["tokens"]
      refute Map.has_key?(listed_token, "raw_token")
      refute Map.has_key?(listed_token, "token_hash")

      assert bearer_ingest(raw_token).status == 202

      rotate_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> post("/api/v1/organizations/#{org_id}/api-tokens/#{api_token["id"]}/rotate")

      rotate_response = json_response(rotate_conn, 201)
      rotated_token = rotate_response["token"]
      rotated_raw_token = rotate_response["raw_token"]

      assert rotated_token["name"] == "ci-token"
      assert rotated_token["role"] == "ci"
      assert rotated_raw_token != raw_token
      assert bearer_ingest(raw_token).status == 401
      assert bearer_ingest(rotated_raw_token).status == 202

      revoke_token_conn =
        build_conn()
        |> authenticated_conn(access_token)
        |> post("/api/v1/organizations/#{org_id}/api-tokens/#{rotated_token["id"]}/revoke")

      assert json_response(revoke_token_conn, 200)["token"]["revoked_at"]
      assert bearer_ingest(rotated_raw_token).status == 401
    end
  end

  defp bearer_ingest(raw_token) do
    build_conn()
    |> put_req_header("authorization", "Bearer #{raw_token}")
    |> post("/otel/v1/traces", %{resourceSpans: []})
  end
end
