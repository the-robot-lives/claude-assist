defmodule TimelyWeb.DeepLinkTest do
  @moduledoc """
  Verified deep links: the https App Link redirect target, and the
  app-association documents that make it verifiable.

  Android chose an https App Link over a custom scheme because a custom scheme
  is claimed by *pattern* and an App Link is ownership-*verified*, which demotes
  PKCE from the only control to defence in depth. These tests confirm the server
  supports that end to end.
  """
  use TimelyWeb.ConnCase, async: false
  use TimelyWeb, :verified_routes

  alias Timely.Auth.SSORedirects

  @app_link "https://timely.noizu.com/app/auth/callback"
  @appauth_single_slash "com.noizu.timely:/oauth2redirect"
  @appauth_double_slash "com.noizu.timely://oauth2redirect"

  setup do
    previous = Application.get_env(:timely, :sso_redirect_allowlist)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:timely, :sso_redirect_allowlist, previous),
        else: Application.delete_env(:timely, :sso_redirect_allowlist)

      Application.delete_env(:timely, :android_app_package)
      Application.delete_env(:timely, :android_app_fingerprints)
      Application.delete_env(:timely, :ios_app_ids)
    end)

    :ok
  end

  describe "an https App Link as a redirect target" do
    setup do
      Application.put_env(:timely, :sso_redirect_allowlist, [@app_link])
      :ok
    end

    test "validates against the allow-list" do
      assert {:ok, @app_link} = SSORedirects.validate(@app_link)
    end

    test "is classified as native, so the redirect is emitted as external" do
      # This is the part that would break silently: an absolute https URL passed
      # to `redirect(to:)` raises, because Phoenix refuses a scheme there as an
      # open-redirect guard. It must take the `external:` branch.
      assert SSORedirects.native?(@app_link)
    end

    test "an https target NOT on the allow-list is not treated as native" do
      # Prevents an arbitrary https string from being handed to `external:`.
      refute SSORedirects.native?("https://evil.example/steal")
    end

    test "the callback actually redirects to it", %{conn: conn} do
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @app_link})
        |> get("/auth/oidc/callback")

      assert result.status == 302
      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @app_link <> "?")
    end

    test "host case is normalized but the path is not", %{conn: _conn} do
      assert {:ok, @app_link} = SSORedirects.validate("https://TIMELY.NOIZU.COM/app/auth/callback")
      # Paths are case-sensitive per RFC 3986; folding them would widen the
      # allow-list past what was configured.
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("https://timely.noizu.com/app/AUTH/callback")
    end

    test "nothing in the flow assumes a custom scheme" do
      # Both forms are first-class: only `native?/1` distinguishes them, and only
      # to choose between `external:` and `to:`.
      Application.put_env(:timely, :sso_redirect_allowlist, [@app_link, @appauth_single_slash])

      assert {:ok, @app_link} = SSORedirects.validate(@app_link)
      assert {:ok, @appauth_single_slash} = SSORedirects.validate(@appauth_single_slash)
      assert SSORedirects.native?(@app_link)
      assert SSORedirects.native?(@appauth_single_slash)
    end
  end

  describe "the FINAL production allow-list" do
    # The exact value ops will set, with both clients' final strings pasted from
    # their sources. Pinned here because `redirect_not_allowed` is the only
    # signal a wrong string produces, and it appears at runtime and nowhere
    # else.
    @android_final "https://timely.noizu.com/app/auth/callback"
    @ios_final "com.noizu.timely://auth/callback"

    setup do
      Application.put_env(:timely, :sso_redirect_allowlist, [@android_final, @ios_final])
      :ok
    end

    test "an App Link and a custom scheme coexist in one allow-list" do
      # Nothing about the allow-list is per-form: entries are exact strings and
      # the two shapes are independent.
      assert {:ok, @android_final} = SSORedirects.validate(@android_final)
      assert {:ok, @ios_final} = SSORedirects.validate(@ios_final)

      assert SSORedirects.native?(@android_final)
      assert SSORedirects.native?(@ios_final)

      # And the web default is still admitted alongside both, unconfigured.
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate(nil)
    end

    test "iOS's DOUBLE-slash form validates", %{conn: conn} do
      # scheme + host + path. Distinct from `com.noizu.timely:/oauth2redirect`
      # (single slash, scheme + path), which is NOT on this list and must not be.
      assert {:ok, @ios_final} = SSORedirects.validate(@ios_final)
      assert {:error, :redirect_not_allowed} = SSORedirects.validate("com.noizu.timely:/auth/callback")

      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @ios_final})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @ios_final <> "?")
    end

    test "Android's App Link redirects correctly", %{conn: conn} do
      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @android_final})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @android_final <> "?")
    end

    test "each still excludes the other's near-misses" do
      # Neither entry widens the other. A typo in one platform's string fails
      # closed rather than falling through to the other platform's target.
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("com.noizu.timely://auth/callback/extra")

      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("https://timely.noizu.com/app/auth/callback2")

      assert {:error, :redirect_not_allowed} = SSORedirects.validate("com.noizu.timely://")
    end
  end

  describe "AppAuth's single-slash form is DISTINCT from the double-slash form" do
    test "one slash and two slashes are different targets" do
      # `com.noizu.timely:/oauth2redirect`  -> scheme + PATH, no authority
      # `com.noizu.timely://oauth2redirect` -> scheme + HOST, no path
      # Different URIs by RFC 3986, and exact-match keeps them different.
      # Allow-listing one does NOT admit the other, and the mismatch surfaces
      # only at runtime as `redirect_not_allowed`.
      Application.put_env(:timely, :sso_redirect_allowlist, [@appauth_single_slash])

      assert {:ok, @appauth_single_slash} = SSORedirects.validate(@appauth_single_slash)
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(@appauth_double_slash)
    end

    test "and the reverse" do
      Application.put_env(:timely, :sso_redirect_allowlist, [@appauth_double_slash])

      assert {:ok, @appauth_double_slash} = SSORedirects.validate(@appauth_double_slash)
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(@appauth_single_slash)
    end

    test "normalization does not collapse them" do
      # Documented deliberately: exact-match means exact. Collapsing them would
      # mean an allow-list entry admitted a target the operator never wrote.
      Application.put_env(:timely, :sso_redirect_allowlist, [
        @appauth_single_slash,
        @appauth_double_slash
      ])

      assert @appauth_single_slash in SSORedirects.allowlist()
      assert @appauth_double_slash in SSORedirects.allowlist()
      assert @appauth_single_slash != @appauth_double_slash
    end

    test "the single-slash form still redirects correctly", %{conn: conn} do
      Application.put_env(:timely, :sso_redirect_allowlist, [@appauth_single_slash])

      result =
        conn
        |> Plug.Test.init_test_session(%{sso_redirect: @appauth_single_slash})
        |> get("/auth/oidc/callback")

      location = List.first(get_resp_header(result, "location"))
      assert String.starts_with?(location, @appauth_single_slash <> "?")
    end
  end

  describe "GET /.well-known/assetlinks.json" do
    test "404s when unconfigured, so verification is not attempted", %{conn: conn} do
      # Fails OPEN into the disambiguation dialog rather than shut. A well-formed
      # file with no matching fingerprint is a definitive REJECTION and a
      # confusing thing to debug; absence is not.
      assert json_response(get(conn, "/.well-known/assetlinks.json"), 404)
    end

    test "serves the package and fingerprints when configured", %{conn: conn} do
      Application.put_env(:timely, :android_app_package, "com.noizu.timely")

      Application.put_env(:timely, :android_app_fingerprints, [
        "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
      ])

      result = get(conn, "/.well-known/assetlinks.json")

      assert result.status == 200
      # No redirect: neither platform's verifier follows one.
      assert get_resp_header(result, "location") == []
      assert ["application/json" <> _] = get_resp_header(result, "content-type")

      assert [entry] = Jason.decode!(result.resp_body)
      assert entry["relation"] == ["delegate_permission/common.handle_all_urls"]
      assert entry["target"]["namespace"] == "android_app"
      assert entry["target"]["package_name"] == "com.noizu.timely"
      assert length(entry["target"]["sha256_cert_fingerprints"]) == 1
    end

    test "404s when the package is set but no fingerprint is", %{conn: conn} do
      Application.put_env(:timely, :android_app_package, "com.noizu.timely")
      Application.put_env(:timely, :android_app_fingerprints, [])

      # A half-configured file would claim the package and grant nothing, which
      # is a rejection rather than an absence.
      assert json_response(get(conn, "/.well-known/assetlinks.json"), 404)
    end

    test "requires no authentication", %{conn: _conn} do
      Application.put_env(:timely, :android_app_package, "com.noizu.timely")
      Application.put_env(:timely, :android_app_fingerprints, ["AA:BB"])

      # A bare conn with no bearer token: verifiers send no credentials.
      assert Phoenix.ConnTest.build_conn()
             |> get("/.well-known/assetlinks.json")
             |> Map.get(:status) == 200
    end
  end

  describe "GET /.well-known/apple-app-site-association" do
    test "is served from an EXTENSIONLESS path as application/json", %{conn: conn} do
      Application.put_env(:timely, :ios_app_ids, ["ABCDE12345.com.noizu.timely"])

      result = get(conn, "/.well-known/apple-app-site-association")

      assert result.status == 200
      assert ["application/json" <> _] = get_resp_header(result, "content-type")
      assert get_resp_header(result, "location") == []

      body = Jason.decode!(result.resp_body)
      assert [detail] = body["applinks"]["details"]
      assert detail["appID"] == "ABCDE12345.com.noizu.timely"
      assert "/app/auth/callback" in detail["paths"]
    end

    test "404s when unconfigured", %{conn: conn} do
      assert json_response(get(conn, "/.well-known/apple-app-site-association"), 404)
    end
  end
end
