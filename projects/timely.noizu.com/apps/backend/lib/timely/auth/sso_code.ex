defmodule Timely.Auth.SSOCode do
  @moduledoc """
  The one-time code handed back at the end of an SSO flow and traded for tokens
  at `POST /api/v1/auth/sso/exchange`.

  32 random bytes, single-use (redeemed with `GETDEL`, so two concurrent
  redemptions cannot both win), and short-lived.

  ## Why this code can carry a PKCE binding

  In a **web** flow the code travels between two pages of the same origin and
  the browser is the only party that sees it.

  In a **native** flow it is delivered to a custom URL scheme, and on both iOS
  and Android a custom scheme is claimed by pattern rather than owned: a
  malicious app registering `com.noizu.timely://` can receive the redirect. The
  code is short-lived and single-use, but an app that wins that race redeems it
  for a full access + refresh token pair.

  PKCE closes it. The app generates a high-entropy `code_verifier`, sends only
  `BASE64URL(SHA256(verifier))` when it starts the flow, and presents the
  verifier at redemption. An app that intercepts the redirect holds the code but
  not the verifier, so the exchange fails.

  Note this is PKCE on **our** code, between the app and this server. It is not
  PKCE against the identity provider, where it does not apply: the *server* is
  the OAuth client there, holding a client secret, and the app never speaks to
  the IdP directly.

  Binding is per code. A code minted with a challenge REQUIRES a matching
  verifier; one minted without a challenge refuses a verifier rather than
  ignoring it, so neither side can silently downgrade.
  """

  @ttl_seconds 60

  @doc """
  Mints a one-time code for a session, optionally bound to a PKCE challenge.
  """
  # ⟦𓎡𓂋𓏏𓋴⟧ create :: Mints a one-time SSO code, optionally PKCE-bound.
  def create(session_id, opts \\ []) do
    code = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    payload =
      Jason.encode!(%{
        "session_id" => to_string(session_id),
        "code_challenge" => Keyword.get(opts, :code_challenge)
      })

    {:ok, _} = Timely.Redis.set("sso_code:#{code}", payload, ex: @ttl_seconds)
    {:ok, code}
  end

  @doc """
  Redeems a code. Single-use: the read deletes it, so a replay finds nothing
  whether or not the first redemption succeeded.

  Returns `{:error, :pkce_required}` when the code was bound and no verifier was
  presented, and `{:error, :pkce_failed}` when the verifier does not match. The
  two are distinguished here for logging and collapsed into one response by the
  controller, so a caller learns nothing from the difference.
  """
  # ⟦𓐍𓎡𓋴𓈖⟧ exchange :: Redeems a one-time SSO code, verifying PKCE.
  def exchange(code, opts \\ []) do
    key = Timely.Redis.prefix("sso_code:#{code}")

    case Timely.Redis.command(["GETDEL", key]) do
      {:ok, nil} -> {:error, :invalid_code}
      {:ok, raw} -> verify(raw, Keyword.get(opts, :code_verifier))
      _ -> {:error, :invalid_code}
    end
  end

  defp verify(raw, verifier) do
    case decode(raw) do
      %{"session_id" => session_id, "code_challenge" => nil} ->
        if blank?(verifier) do
          {:ok, session_id}
        else
          # The code was never bound, so a verifier proves nothing. Refusing it
          # rather than ignoring it stops a client believing PKCE protected an
          # exchange where it did not.
          {:error, :pkce_failed}
        end

      %{"session_id" => session_id, "code_challenge" => challenge} ->
        cond do
          blank?(verifier) -> {:error, :pkce_required}
          matches?(challenge, verifier) -> {:ok, session_id}
          true -> {:error, :pkce_failed}
        end

      _ ->
        {:error, :invalid_code}
    end
  end

  # S256 only. RFC 7636 also permits `plain`, which offers no protection against
  # an interceptor who can see the request that carried the challenge, so it is
  # not accepted.
  defp matches?(challenge, verifier) do
    computed = :sha256 |> :crypto.hash(verifier) |> Base.url_encode64(padding: false)
    Plug.Crypto.secure_compare(computed, challenge)
  end

  # Codes minted before this module stored JSON hold a bare session id, so a
  # deploy mid-flight does not strand the 60 seconds of codes already issued.
  defp decode(raw) do
    case Jason.decode(raw) do
      {:ok, %{"session_id" => _} = payload} -> Map.put_new(payload, "code_challenge", nil)
      _ -> %{"session_id" => raw, "code_challenge" => nil}
    end
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  @doc """
  Validates a client-supplied PKCE challenge before it is stored.

  RFC 7636 fixes the verifier at 43..128 characters of the unreserved
  base64url alphabet; the challenge is a SHA-256 digest in the same alphabet. A
  short challenge would make the verifier guessable and defeat the point, so the
  length floor is enforced rather than assumed.
  """
  # ⟦𓆑𓎡𓋴𓏏⟧ valid_challenge? :: Validates a PKCE code challenge.
  def valid_challenge?(challenge) when is_binary(challenge) do
    byte_size(challenge) >= 43 and byte_size(challenge) <= 128 and
      Regex.match?(~r/^[A-Za-z0-9\-._~]+$/, challenge)
  end

  def valid_challenge?(_), do: false
end
