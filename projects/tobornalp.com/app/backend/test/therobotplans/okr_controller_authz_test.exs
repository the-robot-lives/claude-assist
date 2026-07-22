defmodule TherobotplansWeb.OkrControllerAuthzTest do
  @moduledoc """
  Regression for the OKR cross-org authorization hole: `show`, `update`,
  `create_key_result`, and `create_checkin` previously had NO `Authz.authorize`
  and NO org-membership check, so any authenticated user could read or edit any
  org's OKRs just by knowing (or guessing) the objective UUID.

  Each test authenticates a user who is NOT a member of the objective's org and
  asserts the request is rejected (403). Before the fix, `show` returned 200 with
  the objective body; the others mutated freely.

  Requires the DB schema (Liquibase changelogs) + SQL sandbox — see the
  npl-mix-test-recipe memory.
  """
  use TherobotplansWeb.ConnCase

  alias Therobotplans.Repo
  alias Therobotplans.Domains.Goals

  @moduletag :db

  setup %{conn: conn} do
    # Org A owns a secret objective. The caller is authenticated but is NOT a
    # member of org A, so every OKR action scoped to org A must be forbidden.
    org_a = insert_org("secret-org")

    {:ok, obj} =
      Goals.create_objective(%{"organization_id" => org_a, "title" => "Secret objective"})

    %{access_token: token} = setup_user_and_token()
    attacker = authenticated_conn(conn, token)

    %{attacker: attacker, org_a: org_a, obj: obj}
  end

  test "GET objective as a non-member returns 403", %{attacker: conn, org_a: org_a, obj: obj} do
    conn = get(conn, "/api/v1/organizations/#{org_a}/objectives/#{obj.id}")
    assert json_response(conn, 403)
  end

  test "PATCH objective as a non-member returns 403 and does not mutate", %{
    attacker: conn,
    org_a: org_a,
    obj: obj
  } do
    conn =
      patch(conn, "/api/v1/organizations/#{org_a}/objectives/#{obj.id}", %{
        objective: %{title: "hacked"}
      })

    assert json_response(conn, 403)
    assert Goals.get_objective(obj.id).title == "Secret objective"
  end

  test "POST key_result as a non-member returns 403", %{
    attacker: conn,
    org_a: org_a,
    obj: obj
  } do
    conn =
      post(conn, "/api/v1/organizations/#{org_a}/objectives/#{obj.id}/key_results", %{
        key_result: %{title: "smuggled KR"}
      })

    assert json_response(conn, 403)
  end

  test "POST checkin as a non-member returns 403", %{
    attacker: conn,
    org_a: org_a,
    obj: obj
  } do
    conn =
      post(conn, "/api/v1/organizations/#{org_a}/objectives/#{obj.id}/checkins", %{
        checkin: %{body: "smuggled check-in", period: "2026-Q3"}
      })

    assert json_response(conn, 403)
  end

  defp insert_org(slug) do
    %{rows: [[raw]]} =
      Repo.query!(
        "INSERT INTO organizations (id, slug, name, inserted_at, updated_at) " <>
          "VALUES (gen_random_uuid(), $1, $2, now(), now()) RETURNING id",
        ["#{slug}-#{System.unique_integer([:positive])}" |> String.slice(0, 40), "Org"]
      )

    Ecto.UUID.load!(raw)
  end
end
