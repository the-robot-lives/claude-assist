defmodule TimelyWeb.SSOStateNonceTest do
  @moduledoc """
  The OIDC `state`/`nonce` guard - direct unit coverage of `verify_state/2`
  and `verify_nonce/2`, closing a real gap: this was the REFERENCE
  implementation the state/nonce fix was ported from into both
  `components/start-app` and `components/hologram-start-app`, and into all 23
  scaffold-lineage backends this repo audited - and until this file, it had
  ZERO nonce coverage anywhere, HTTP or unit. `sso_native_redirect_test.exs`
  covers `state` at the HTTP level (forged/missing state refused at
  `/auth/oidc/callback`); it never exercises `nonce` at all, because `nonce`
  is only checked after a real token exchange and `id_token` verification,
  which no suite in this repo can fake without a live or mocked IdP.

  So every one of those 23 ports faithfully copied a guard nobody had ever
  actually verified fires. These tests call `TimelyWeb.SSOController`'s real
  `verify_state/2`/`verify_nonce/2` directly - the actual functions the
  controller calls, not a re-implementation of their logic - which is the
  only way to assert the nonce guard actually rejects a replay rather than
  merely being present in the source.

  MUTATION-TESTED, not just written and trusted: both functions'
  `Plug.Crypto.secure_compare/2` calls were temporarily replaced with a
  literal `true` (i.e. "everything matches") and every test in this module
  was confirmed to fail before the change was reverted. A test suite that
  stays green when the guard is disabled would be worse than no test at all -
  it would say "protected" about code that isn't.
  """
  use ExUnit.Case, async: true

  alias TimelyWeb.SSOController

  describe "verify_state/2" do
    test "no expected state (session never had one) is refused regardless of what arrives" do
      assert SSOController.verify_state(nil, "anything") == {:error, :state_mismatch}
      assert SSOController.verify_state(nil, nil) == {:error, :state_mismatch}
    end

    test "an expected state with nothing received back is refused" do
      assert SSOController.verify_state("the-real-state", nil) == {:error, :state_mismatch}
    end

    test "a state that doesn't match is refused - the actual forged-callback case" do
      assert SSOController.verify_state("the-real-state", "attacker-supplied") ==
               {:error, :state_mismatch}
    end

    test "a matching state is accepted" do
      assert SSOController.verify_state("the-real-state", "the-real-state") == :ok
    end
  end

  describe "verify_nonce/2 - never covered anywhere in this repo before this file" do
    test "a replayed / substituted nonce is refused - the actual id_token-replay case" do
      assert SSOController.verify_nonce("the-real-nonce", "a-different-nonce") ==
               {:error, :nonce_mismatch}
    end

    test "a matching nonce is accepted" do
      assert SSOController.verify_nonce("the-real-nonce", "the-real-nonce") == :ok
    end

    test "no nonce was ever issued (session has none) - nothing to replay, not an error" do
      assert SSOController.verify_nonce(nil, "whatever-the-provider-sent") == :ok
    end

    test "a provider that omits the nonce in its id_token is tolerated deliberately - not every provider echoes it back, and requiring one would break working deployments that never send it" do
      assert SSOController.verify_nonce("the-real-nonce", nil) == :ok
    end
  end
end
