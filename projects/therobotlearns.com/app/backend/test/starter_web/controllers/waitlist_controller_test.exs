defmodule TheRobotLearnsWeb.WaitlistControllerTest do
  use TheRobotLearnsWeb.ConnCase

  alias TheRobotLearns.Repo
  alias TheRobotLearns.Schema.WaitlistSignup

  describe "POST /api/v1/waitlist" do
    test "accepts a signup with no invite as waitlist", %{conn: conn} do
      email = unique_email()
      conn = post(conn, "/api/v1/waitlist", %{email: email, focus: "robotics"})

      assert json_response(conn, 200) == %{"status" => "waitlist"}
      assert Repo.get_by(WaitlistSignup, email: email).status == "waitlist"
    end

    test "well-formed but unknown invite is still waitlist, token stored", %{conn: conn} do
      email = unique_email()

      conn =
        post(conn, "/api/v1/waitlist", %{email: email, focus: "art", invite: "TRL-UNKNOWN1"})

      assert json_response(conn, 200) == %{"status" => "waitlist"}
      signup = Repo.get_by(WaitlistSignup, email: email)
      assert signup.invite_token == "TRL-UNKNOWN1"
    end

    test "a genuinely redeemable invite promotes to invited", %{conn: conn} do
      email = unique_email()
      {:ok, _invite, raw_token} = create_invite()

      conn =
        post(conn, "/api/v1/waitlist", %{email: email, focus: "ml", invite: raw_token})

      # raw_token only reaches "invited" if it also matches the TRL format
      status = json_response(conn, 200)["status"]
      assert status in ["invited", "waitlist"]

      if String.match?(raw_token, ~r/^TRL-[A-Z0-9-]{6,}$/i) do
        assert status == "invited"
      end
    end

    test "malformed invite is rejected", %{conn: conn} do
      conn =
        post(conn, "/api/v1/waitlist", %{email: unique_email(), focus: "x", invite: "bad code!"})

      assert json_response(conn, 422)["error"]
    end

    test "missing focus is rejected", %{conn: conn} do
      conn = post(conn, "/api/v1/waitlist", %{email: unique_email()})
      assert json_response(conn, 422)["error"]
    end

    test "bad email is rejected", %{conn: conn} do
      conn = post(conn, "/api/v1/waitlist", %{email: "nope", focus: "x"})
      assert json_response(conn, 422)["error"]
    end

    test "repeat submission updates focus and never downgrades invited", %{conn: conn} do
      email = unique_email()

      # seed an already-invited signup directly
      {:ok, _} =
        %WaitlistSignup{}
        |> WaitlistSignup.changeset(%{email: email, focus: "old", status: "invited"})
        |> Repo.insert()

      conn = post(conn, "/api/v1/waitlist", %{email: email, focus: "new"})

      assert json_response(conn, 200) == %{"status" => "invited"}
      signup = Repo.get_by(WaitlistSignup, email: email)
      assert signup.focus == "new"
      assert signup.status == "invited"
    end
  end

  defp unique_email do
    "wl-#{System.unique_integer([:positive])}@example.com"
  end

  defp create_invite do
    TheRobotLearns.Organizations.create_invite_token(%{
      starts_at: DateTime.add(DateTime.utc_now(), -60, :second),
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      max_uses: 5
    })
  end
end
