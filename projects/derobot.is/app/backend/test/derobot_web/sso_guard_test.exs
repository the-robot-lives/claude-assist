defmodule DerobotWeb.SSOGuardTest do
  @moduledoc """
  Unit tests for the OIDC login-CSRF and replay guards.

  Plain `ExUnit.Case` against the real `verify_state/2` and `verify_nonce/2` --
  no database, no HTTP, no identity provider. That is not a convenience: the
  nonce guard runs only AFTER a successful token exchange, so a controller-level
  test could not reach it without a live or mocked IdP, and it would have gone
  untested the way it is untested nearly everywhere else in this repo.

  These assert the ATTACK is refused, not merely that the guard exists. A test
  that only checked the happy path would pass against a guard that returned `:ok`
  unconditionally.
  """
  use ExUnit.Case, async: true

  alias DerobotWeb.SSOController

  describe "verify_state/2 - login CSRF" do
    test "refuses a forged state" do
      # The attack: a victim is walked through a flow the attacker started, so
      # the victim's browser ends up signed in AS THE ATTACKER and subsequent
      # work is typed into the attacker's account.
      assert {:error, :state_mismatch} =
               SSOController.verify_state("session-state", "attacker-state")
    end

    test "refuses when the session carries no state" do
      # A callback arriving with no prior flow in this browser. Before the fix
      # this was the ONLY case that existed, and it was accepted.
      assert {:error, :state_mismatch} = SSOController.verify_state(nil, "anything")
    end

    test "refuses when the callback carries no state" do
      assert {:error, :state_mismatch} = SSOController.verify_state("session-state", nil)
    end

    test "refuses when both are absent" do
      # Must NOT degrade to `nil == nil` and pass.
      assert {:error, :state_mismatch} = SSOController.verify_state(nil, nil)
    end

    test "accepts a matching state" do
      assert :ok = SSOController.verify_state("session-state", "session-state")
    end

    test "is not satisfied by a prefix or a suffix" do
      assert {:error, :state_mismatch} = SSOController.verify_state("abc123", "abc")
      assert {:error, :state_mismatch} = SSOController.verify_state("abc", "abc123")
    end

    test "distinguishes values differing in one character" do
      a = String.duplicate("a", 43)
      assert {:error, :state_mismatch} = SSOController.verify_state(a, a <> "b")

      assert {:error, :state_mismatch} =
               SSOController.verify_state(a, String.replace_suffix(a, "a", "b"))
    end
  end

  describe "verify_nonce/2 - id_token replay" do
    test "refuses a nonce that does not match the one we issued" do
      # The replay case, and the only test that can reach this function at all
      # without an IdP.
      assert {:error, :nonce_mismatch} =
               SSOController.verify_nonce("issued-nonce", "replayed-nonce")
    end

    test "accepts a matching nonce" do
      assert :ok = SSOController.verify_nonce("issued-nonce", "issued-nonce")
    end

    test "TOLERATES an absent nonce in the claims, deliberately" do
      # Not every provider echoes `nonce` back in the id_token. Requiring it
      # would break working deployments, so absence is accepted and only a
      # DIFFERING value is refused.
      #
      # Asserted rather than left implicit so that someone "hardening" this
      # later has to delete a test that says why, instead of silently changing
      # behaviour that looks like an oversight.
      assert :ok = SSOController.verify_nonce("issued-nonce", nil)
    end

    test "tolerates a session with no nonce recorded" do
      # A flow begun before this deploy, mid-upgrade. Same reasoning.
      assert :ok = SSOController.verify_nonce(nil, "whatever")
    end

    test "distinguishes values differing in one character" do
      n = String.duplicate("n", 43)
      assert {:error, :nonce_mismatch} = SSOController.verify_nonce(n, n <> "x")
    end
  end

  describe "the guards are not trivially permissive" do
    test "verify_state never returns :ok for differing inputs" do
      # A guard replaced by `true` or `_ -> :ok` passes any single happy-path
      # test. This sweeps a range of mismatches so that degradation cannot hide.
      for {a, b} <- [
            {"", "x"},
            {"x", ""},
            {"State", "state"},
            {"state ", "state"},
            {String.duplicate("z", 128), String.duplicate("z", 127)}
          ] do
        assert {:error, :state_mismatch} = SSOController.verify_state(a, b),
               "verify_state accepted #{inspect(a)} vs #{inspect(b)}"
      end
    end

    test "verify_nonce never returns :ok for two differing present values" do
      for {a, b} <- [{"", "x"}, {"x", ""}, {"Nonce", "nonce"}, {"n1", "n2"}] do
        assert {:error, :nonce_mismatch} = SSOController.verify_nonce(a, b),
               "verify_nonce accepted #{inspect(a)} vs #{inspect(b)}"
      end
    end
  end
end
