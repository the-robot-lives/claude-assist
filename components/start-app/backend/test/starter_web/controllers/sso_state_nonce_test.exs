defmodule StarterWeb.SSOStateNonceTest do
  @moduledoc """
  The OIDC `state`/`nonce` guard at the HTTP level.

  The bug being fixed: `oidc_init/2` called `authorization_uri/2` with no
  `state` and no `nonce`, and `oidc_callback/2` never checked either on the
  way back in - a login-CSRF and id_token-replay gap. Ueberauth already
  protects the social-provider paths with its own CSRF state; the raw OIDC
  path was the hole.

  These tests exercise only the callback's state check, by seeding the
  session directly with `Plug.Test.init_test_session/2` rather than driving
  a real `/auth/oidc` init round-trip - this scaffold has no OIDC provider
  configured in `:test`, so a live `authorization_uri`/`fetch_tokens` call
  would need a reachable issuer. That the tests below pass without one is
  itself a check on the fix: `verify_state/2` runs BEFORE `oidc_config/0` in
  the `oidc_callback/2` `with` chain, so a state mismatch short-circuits
  before the controller ever tries to read OIDC config. If that ordering
  regressed and config were read first, these tests would fail with a 500
  (`Application.fetch_env!` raising), not a clean redirect.
  """
  use StarterWeb.ConnCase, async: true

  # No :frontend_url in config/test.exs, so the controller falls back to its
  # own inline default - asserted here rather than assumed, since a redirect
  # to the wrong host would still "pass" a bare `error=state_mismatch` check.
  @frontend_url "http://localhost:3000"

  describe "GET /auth/oidc/callback - state" do
    test "a callback with no state in session is refused", %{conn: conn} do
      result =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/auth/oidc/callback?code=stolen&state=attacker-supplied")

      assert result.status == 302
      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @frontend_url)
      assert location =~ "error=state_mismatch"
    end

    test "a callback whose state does not match the session is refused", %{conn: conn} do
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_state: "the-real-state"})
        |> get("/auth/oidc/callback?code=stolen&state=a-different-state")

      assert result.status == 302
      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @frontend_url)
      assert location =~ "error=state_mismatch"
    end

    test "a callback with no code and no state still fails closed to oidc_failed, not a crash", %{
      conn: conn
    } do
      result =
        conn
        |> Plug.Test.init_test_session(%{})
        |> get("/auth/oidc/callback")

      assert result.status == 302
      location = List.first(get_resp_header(result, "location"))
      assert location =~ "error=oidc_failed"
    end
  end
end
