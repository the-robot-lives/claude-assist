defmodule TimelyWeb.SSONativeRedirectTest do
  @moduledoc """
  The native SSO redirect at the HTTP level.

  The bug being fixed: `handle_sso_callback` redirected to a relative WEB path,
  and `ASWebAuthenticationSession` only returns control to the app when the
  browser reaches the app's OWN URL scheme. A relative https path never does, so
  the session hung and native SSO could not complete. Android's AppAuth has the
  same requirement.
  """
  use TimelyWeb.ConnCase, async: false
  use TimelyWeb, :verified_routes

  alias Timely.Auth.SSOCode
  alias Timely.Auth.SSORedirects

  @native "com.noizu.timely://auth/callback"
  @verifier "dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  @challenge :sha256 |> :crypto.hash(@verifier) |> Base.url_encode64(padding: false)

  setup do
    previous = Application.get_env(:timely, :sso_redirect_allowlist)
    Application.put_env(:timely, :sso_redirect_allowlist, [@native])

    on_exit(fn ->
      if previous,
        do: Application.put_env(:timely, :sso_redirect_allowlist, previous),
        else: Application.delete_env(:timely, :sso_redirect_allowlist)
    end)

    :ok
  end

  describe "POST /api/v1/auth/sso/exchange" do
    test "an unbound code exchanges without a verifier", %{conn: conn} do
      %{session: session, user: user} = setup_user_and_token()
      {:ok, code} = SSOCode.create(session.id)

      body =
        conn
        |> post(~p"/api/v1/auth/sso/exchange", %{"code" => code})
        |> json_response(200)

      assert body["user"]["id"] == user.id
      # Confirms the field name the mobile agents asked about: access_token and
      # refresh_token, never a bare `token`.
      assert is_binary(body["access_token"])
      assert is_binary(body["refresh_token"])
    end

    test "a PKCE-bound code exchanges with the matching verifier", %{conn: conn} do
      %{session: session} = setup_user_and_token()
      {:ok, code} = SSOCode.create(session.id, code_challenge: @challenge)

      body =
        conn
        |> post(~p"/api/v1/auth/sso/exchange", %{
          "code" => code,
          "code_verifier" => @verifier
        })
        |> json_response(200)

      assert is_binary(body["access_token"])
    end

    test "a PKCE-bound code is refused without a verifier", %{conn: conn} do
      %{session: session} = setup_user_and_token()
      {:ok, code} = SSOCode.create(session.id, code_challenge: @challenge)

      # The interception case: a hostile app holding the redirect has the code
      # and cannot use it.
      assert json_response(post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => code}), 401)
    end

    test "a PKCE-bound code is refused with a wrong verifier", %{conn: conn} do
      %{session: session} = setup_user_and_token()
      {:ok, code} = SSOCode.create(session.id, code_challenge: @challenge)

      assert json_response(
               post(conn, ~p"/api/v1/auth/sso/exchange", %{
                 "code" => code,
                 "code_verifier" => "wrong-verifier-but-long-enough-to-look-plausible"
               }),
               401
             )
    end

    test "every failure answers identically, so nothing is learned from the difference", %{
      conn: conn
    } do
      %{session: session} = setup_user_and_token()
      {:ok, bound} = SSOCode.create(session.id, code_challenge: @challenge)

      missing = post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => bound}) |> json_response(401)

      {:ok, bound2} = SSOCode.create(session.id, code_challenge: @challenge)

      wrong =
        post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => bound2, "code_verifier" => "nope"})
        |> json_response(401)

      unknown =
        post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => "never-issued"})
        |> json_response(401)

      assert missing == wrong
      assert wrong == unknown
    end

    test "a code is single-use over HTTP", %{conn: conn} do
      %{session: session} = setup_user_and_token()
      {:ok, code} = SSOCode.create(session.id)

      assert json_response(post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => code}), 200)
      assert json_response(post(conn, ~p"/api/v1/auth/sso/exchange", %{"code" => code}), 401)
    end
  end

  describe "GET /auth/oidc — starting a flow" do
    test "an unlisted redirect_uri is refused before the user leaves", %{conn: conn} do
      # Refused at init rather than at callback: the user must not be sent to
      # the provider at all for a flow whose landing place is not permitted.
      body =
        conn
        |> get(~p"/auth/oidc?redirect_uri=https://evil.example/steal")
        |> json_response(400)

      assert body["error"] == "redirect_not_allowed"
    end

    test "a malformed code_challenge is refused", %{conn: conn} do
      body =
        conn
        |> get(~p"/auth/oidc?redirect_uri=#{@native}&code_challenge=tooshort")
        |> json_response(400)

      assert body["error"] == "invalid_code_challenge"
    end

    test "an unsupported code_challenge_method is refused", %{conn: conn} do
      # `plain` offers no protection against an interceptor who saw the
      # challenge, so S256 is the only accepted method.
      body =
        conn
        |> get(
          ~p"/auth/oidc?redirect_uri=#{@native}&code_challenge=#{@challenge}&code_challenge_method=plain"
        )
        |> json_response(400)

      assert body["error"] == "invalid_code_challenge"
    end
  end

  describe "the redirect itself — the actual bug" do
    test "a native flow hands back to the app's OWN scheme", %{conn: conn} do
      # THE regression test. Before this change the Location header was the
      # relative web path `/auth/sso-callback?...`, which the browser follows
      # without ever leaving https - so ASWebAuthenticationSession never
      # regained control and the app hung with no error to show.
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @native})
        |> get("/auth/oidc/callback")

      assert result.status == 302
      location = List.first(get_resp_header(result, "location"))

      assert String.starts_with?(location, "com.noizu.timely://auth/callback")
      refute String.starts_with?(location, "/auth/sso-callback")
    end

    test "errors go to the native target too, so the session closes", %{conn: conn} do
      # An error reported to the web page would leave the authentication session
      # open with nothing to return to - the same hang, by a different route.
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @native})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert location =~ "error=oidc_failed"
      assert String.starts_with?(location, @native)
    end

    test "a web flow still gets the relative path, unchanged", %{conn: conn} do
      # The Hologram dashboard depends on this and must not have moved.
      result =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, "/auth/sso-callback")
    end

    test "a session naming a target since removed from the allow-list falls back to web", %{
      conn: conn
    } do
      # Re-validated at redirect time, not merely trusted from the signed
      # session, so revoking a target takes effect for flows already in flight.
      Application.put_env(:timely, :sso_redirect_allowlist, [])

      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @native})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, "/auth/sso-callback")
    end
  end

  describe "OIDC state — a gap that predated native support" do
    test "a callback with no state in session is refused", %{conn: conn} do
      # The OIDC flow previously passed neither state nor nonce, leaving it open
      # to login-CSRF: an attacker completes a flow so the victim is silently
      # signed in as the attacker. Ueberauth already did this for the social
      # providers; OIDC was the hole.
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @native})
        |> get("/auth/oidc/callback?code=stolen&state=attacker-supplied")

      location = List.first(get_resp_header(result, "location"))
      assert location =~ "error=state_mismatch"
    end

    test "a callback whose state does not match the session is refused", %{conn: conn} do
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @native, sso_state: "the-real-state"})
        |> get("/auth/oidc/callback?code=stolen&state=a-different-state")

      location = List.first(get_resp_header(result, "location"))
      assert location =~ "error=state_mismatch"
    end
  end

  describe "the allow-list wiring is live, not just unit-tested" do
    test "the configured native target validates through the real config" do
      assert {:ok, @native} = SSORedirects.validate(@native)
      assert SSORedirects.native?(@native)
    end

    test "the web default still wins when nothing is requested" do
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate(nil)
      refute SSORedirects.native?("/auth/sso-callback")
    end
  end
end
