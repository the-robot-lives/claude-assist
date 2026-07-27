defmodule Timely.Auth.SSOCodeTest do
  @moduledoc """
  The one-time SSO code and its PKCE binding.

  The threat this guards is specific: on iOS and Android a custom URL scheme is
  claimed by pattern, not owned, so a malicious app registering
  `com.noizu.timely://` can receive the redirect that carries this code. Being
  single-use and short-lived is not enough - an app that wins the race redeems
  it for a full token pair. The verifier is what it cannot obtain.
  """
  use ExUnit.Case, async: false

  alias Timely.Auth.SSOCode

  # A verifier of the RFC 7636 minimum length, and its S256 challenge.
  @verifier "dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  @challenge :sha256 |> :crypto.hash(@verifier) |> Base.url_encode64(padding: false)

  describe "unbound codes (the web flow)" do
    test "round-trip without a verifier" do
      session_id = Ecto.UUID.generate()
      {:ok, code} = SSOCode.create(session_id)

      assert {:ok, ^session_id} = SSOCode.exchange(code)
    end

    test "are single-use" do
      {:ok, code} = SSOCode.create(Ecto.UUID.generate())

      assert {:ok, _} = SSOCode.exchange(code)
      # GETDEL, so the second redemption finds nothing whether or not the first
      # succeeded downstream.
      assert {:error, :invalid_code} = SSOCode.exchange(code)
    end

    test "refuse a verifier rather than ignoring one" do
      {:ok, code} = SSOCode.create(Ecto.UUID.generate())

      # A client that sent a verifier believes PKCE protected this exchange. It
      # did not - the code was never bound - so saying so is safer than
      # succeeding and letting the belief stand.
      assert {:error, :pkce_failed} = SSOCode.exchange(code, code_verifier: @verifier)
    end
  end

  describe "bound codes (the native flow)" do
    test "round-trip with the matching verifier" do
      session_id = Ecto.UUID.generate()
      {:ok, code} = SSOCode.create(session_id, code_challenge: @challenge)

      assert {:ok, ^session_id} = SSOCode.exchange(code, code_verifier: @verifier)
    end

    test "an intercepted code is useless without the verifier" do
      # The whole point: a hostile app holding the redirect has the code and
      # nothing else.
      {:ok, code} = SSOCode.create(Ecto.UUID.generate(), code_challenge: @challenge)

      assert {:error, :pkce_required} = SSOCode.exchange(code)
    end

    test "a wrong verifier is rejected" do
      {:ok, code} = SSOCode.create(Ecto.UUID.generate(), code_challenge: @challenge)

      assert {:error, :pkce_failed} =
               SSOCode.exchange(code, code_verifier: "not-the-right-verifier-at-all-padding-xx")
    end

    test "a failed PKCE attempt still consumes the code" do
      {:ok, code} = SSOCode.create(Ecto.UUID.generate(), code_challenge: @challenge)

      assert {:error, :pkce_required} = SSOCode.exchange(code)
      # No retry window: an attacker cannot probe verifiers against a live code,
      # and the legitimate client restarts the flow.
      assert {:error, :invalid_code} = SSOCode.exchange(code, code_verifier: @verifier)
    end

    test "the challenge is compared as S256, not as the raw verifier" do
      # `plain` PKCE would make the challenge and verifier identical, which
      # offers nothing against an interceptor who saw the challenge.
      {:ok, code} = SSOCode.create(Ecto.UUID.generate(), code_challenge: @challenge)

      assert {:error, :pkce_failed} = SSOCode.exchange(code, code_verifier: @challenge)
    end
  end

  describe "valid_challenge?/1" do
    test "accepts an RFC 7636 challenge" do
      assert SSOCode.valid_challenge?(@challenge)
      assert SSOCode.valid_challenge?(String.duplicate("a", 43))
      assert SSOCode.valid_challenge?(String.duplicate("a", 128))
    end

    test "rejects one short enough to brute-force" do
      refute SSOCode.valid_challenge?(String.duplicate("a", 42))
      refute SSOCode.valid_challenge?("short")
      refute SSOCode.valid_challenge?("")
    end

    test "rejects over-long and non-base64url input" do
      refute SSOCode.valid_challenge?(String.duplicate("a", 129))
      refute SSOCode.valid_challenge?(String.duplicate("a", 42) <> "+/=")
      refute SSOCode.valid_challenge?(String.duplicate("a", 42) <> " ")
      refute SSOCode.valid_challenge?(nil)
      refute SSOCode.valid_challenge?(123)
    end
  end

  describe "expiry" do
    test "an unknown code is invalid" do
      assert {:error, :invalid_code} = SSOCode.exchange("never-issued")
    end
  end
end
