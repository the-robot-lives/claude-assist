defmodule Timely.Auth.SSORedirectsTest do
  @moduledoc """
  The redirect allow-list.

  Most of these are attack cases. The redirect carries a one-time code that
  `/auth/sso/exchange` trades for an access and refresh token pair, so a target
  that gets through this check receives a live credential for whoever completed
  the flow.
  """
  use ExUnit.Case, async: false

  alias Timely.Auth.SSORedirects

  @native "com.noizu.timely://auth/callback"
  @app_link "https://timely.noizu.com/auth/native-callback"

  setup do
    previous = Application.get_env(:timely, :sso_redirect_allowlist)
    Application.put_env(:timely, :sso_redirect_allowlist, [@native, @app_link])

    on_exit(fn ->
      if previous,
        do: Application.put_env(:timely, :sso_redirect_allowlist, previous),
        else: Application.delete_env(:timely, :sso_redirect_allowlist)
    end)

    :ok
  end

  describe "the default web target" do
    test "is used when the client asks for nothing" do
      # This is what keeps the Hologram dashboard working unchanged: a browser
      # that never sends redirect_uri gets exactly the previous behaviour.
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate(nil)
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate("")
    end

    test "is always allowed without being configured" do
      Application.put_env(:timely, :sso_redirect_allowlist, [])
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate("/auth/sso-callback")
    end

    test "is not treated as a native target" do
      refute SSORedirects.native?("/auth/sso-callback")
    end
  end

  describe "allow-listed targets" do
    test "an exactly matching custom scheme is accepted" do
      assert {:ok, @native} = SSORedirects.validate(@native)
      assert SSORedirects.native?(@native)
    end

    test "an exactly matching https App Link is accepted" do
      assert {:ok, @app_link} = SSORedirects.validate(@app_link)
    end

    test "scheme and host are matched case-insensitively, per RFC 3986" do
      assert {:ok, @native} = SSORedirects.validate("COM.NOIZU.TIMELY://auth/callback")
      assert {:ok, @app_link} = SSORedirects.validate("https://TIMELY.NOIZU.COM/auth/native-callback")
    end

    test "a trailing slash does not defeat the match" do
      assert {:ok, @native} = SSORedirects.validate(@native <> "/")
    end
  end

  describe "rejections" do
    test "an unlisted target is refused" do
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("https://evil.example/steal")
    end

    test "an unlisted custom scheme is refused" do
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("com.attacker.app://auth/callback")
    end

    test "a prefix of an allow-listed entry is refused" do
      # The classic bypass of `startsWith`: userinfo makes the authority
      # `evil.example` while the string still begins with the allowed value.
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("com.noizu.timely://auth/callback@evil.example")

      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("https://timely.noizu.com.evil.example/auth/native-callback")

      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("https://timely.noizu.com/auth/native-callback/../../evil")
    end

    test "a path is matched case-SENSITIVELY" do
      # Only scheme and host are case-insensitive. Folding the path would widen
      # the allow-list beyond what was configured.
      assert {:error, :redirect_not_allowed} =
               SSORedirects.validate("com.noizu.timely://auth/CALLBACK")
    end

    test "a target carrying its own query or fragment is refused" do
      # The server appends ?code=…; a supplied query would let a caller smuggle
      # parameters the callback then parses.
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(@native <> "?foo=bar")
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(@native <> "#frag")
    end

    test "protocol-relative and javascript targets are refused" do
      assert {:error, :redirect_not_allowed} = SSORedirects.validate("//evil.example/steal")
      assert {:error, :redirect_not_allowed} = SSORedirects.validate("javascript:alert(1)")
      assert {:error, :redirect_not_allowed} = SSORedirects.validate("data:text/html,<script>")
    end

    test "a non-binary target is refused rather than crashing" do
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(%{})
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(123)
    end

    test "an empty allow-list admits nothing but the web default" do
      Application.put_env(:timely, :sso_redirect_allowlist, [])
      assert {:error, :redirect_not_allowed} = SSORedirects.validate(@native)
      assert {:ok, "/auth/sso-callback"} = SSORedirects.validate(nil)
    end
  end

  describe "with_params/2" do
    test "appends a query to a custom scheme" do
      assert SSORedirects.with_params(@native, %{"code" => "abc"}) ==
               @native <> "?code=abc"
    end

    test "appends a query to the relative web path" do
      assert SSORedirects.with_params("/auth/sso-callback", %{"error" => "sso_failed"}) ==
               "/auth/sso-callback?error=sso_failed"
    end

    test "url-encodes values" do
      assert SSORedirects.with_params(@native, %{"code" => "a b&c"}) =~ "code=a+b%26c"
    end
  end
end
