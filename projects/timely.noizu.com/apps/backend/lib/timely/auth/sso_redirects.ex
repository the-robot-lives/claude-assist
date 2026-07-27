defmodule Timely.Auth.SSORedirects do
  @moduledoc """
  The allow-list of places an SSO flow is permitted to hand back its one-time
  code.

  ## Why this is an allow-list and not a reflected parameter

  The redirect carries a credential. `/auth/sso/exchange` will trade that code
  for an access token and a refresh token, so anything that can observe the
  redirect can take over the account. Reflecting a client-supplied
  `redirect_uri` would therefore be a token-exfiltration vector, not merely an
  open redirect: an attacker who can start a flow with
  `redirect_uri=https://evil.example/steal` receives a live code for whoever
  completes it.

  Matching is **exact string equality** against a configured entry, after
  normalizing case in the scheme and host. Deliberately not prefix matching:
  `startsWith("com.noizu.timely://")` is satisfied by
  `com.noizu.timely://auth/callback@evil.example`, and `startsWith("https://timely.noizu.com")`
  by `https://timely.noizu.com.evil.example`. Both are standard bypasses of
  exactly the check people reach for first.

  A target carrying its own query or fragment is refused outright, because the
  server appends `?code=…` and a supplied query would let a caller smuggle
  parameters the callback then parses.

  ## Configuration

      config :timely, :sso_redirect_allowlist, [
        "com.noizu.timely://auth/callback",
        "https://timely.noizu.com/auth/sso-callback"
      ]

  Populated from `SSO_REDIRECT_ALLOWLIST` (comma-separated) in `runtime.exs`.
  The default web target is always allowed and never needs listing.
  """

  # The existing web flow's target. Relative, same-origin, and the value used
  # when a client asks for nothing - which is what keeps the Hologram dashboard
  # working unchanged.
  @web_default "/auth/sso-callback"

  @doc "The default (web) redirect target."
  # ⟦𓅱𓂧𓆑𓏏⟧ default :: The default web redirect target.
  def default, do: @web_default

  @doc """
  Validates a client-supplied redirect target.

  Returns `{:ok, target}` for an allow-listed value, `{:ok, default()}` when the
  client asked for nothing, and `{:error, :redirect_not_allowed}` otherwise.
  """
  # ⟦𓎡𓋴𓂋𓏏⟧ validate :: Validates a redirect target against the allow-list.
  def validate(nil), do: {:ok, @web_default}
  def validate(""), do: {:ok, @web_default}

  def validate(candidate) when is_binary(candidate) do
    with :ok <- reject_query_or_fragment(candidate),
         normalized <- normalize(candidate),
         true <- normalized in allowlist() do
      {:ok, normalized}
    else
      _ -> {:error, :redirect_not_allowed}
    end
  end

  def validate(_candidate), do: {:error, :redirect_not_allowed}

  @doc """
  True when the target hands control back to a native app rather than to a page
  in the same browser.

  Used only to decide how to render an *error*: a native client needs the error
  delivered to its own scheme so the authentication session closes, whereas the
  web app renders it in place.
  """
  # ⟦𓈖𓏏𓆑𓋴⟧ native? :: True for a target that returns to a native app.
  def native?(target) when is_binary(target) do
    case URI.parse(target) do
      %URI{scheme: nil} -> false
      %URI{scheme: "http"} -> false
      %URI{scheme: "https"} -> https_app_link?(target)
      _ -> true
    end
  end

  def native?(_), do: false

  @doc "The configured allow-list, normalized. The web default is always included."
  # ⟦𓄿𓃭𓃭𓅱⟧ allowlist :: The configured redirect allow-list.
  def allowlist do
    :timely
    |> Application.get_env(:sso_redirect_allowlist, [])
    |> List.wrap()
    |> Enum.map(&normalize/1)
    |> Enum.reject(&(&1 == ""))
    |> Kernel.++([@web_default])
    |> Enum.uniq()
  end

  @doc """
  Appends parameters to a redirect target, whichever form it takes.

  A custom-scheme target and a relative web path need different treatment and
  the difference is easy to get wrong, so it lives here rather than at each
  call site.
  """
  # ⟦𓊪𓂋𓅓𓋴⟧ with_params :: Appends query parameters to a redirect target.
  def with_params(target, params) do
    query = URI.encode_query(params)

    separator = if String.contains?(target, "?"), do: "&", else: "?"
    target <> separator <> query
  end

  # An https target is only a native hand-back if it is registered as an App
  # Link / Universal Link, which the server cannot verify. It is treated as web
  # for error-rendering purposes; the app still receives it if the OS has the
  # association, and nothing about correctness depends on this guess.
  defp https_app_link?(target) do
    target != @web_default and
      target in Enum.filter(allowlist(), &String.starts_with?(&1, "https://"))
  end

  defp reject_query_or_fragment(candidate) do
    if String.contains?(candidate, "?") or String.contains?(candidate, "#"),
      do: :error,
      else: :ok
  end

  # Case-insensitive in scheme and host per RFC 3986, case-SENSITIVE in the
  # path, because that is what the RFC says and a path comparison that ignored
  # case would widen the allow-list.
  defp normalize(value) when is_binary(value) do
    value = String.trim(value)

    case URI.parse(value) do
      %URI{scheme: nil} ->
        String.trim_trailing(value, "/")

      %URI{scheme: scheme, host: host} = uri ->
        %{uri | scheme: String.downcase(scheme), host: host && String.downcase(host)}
        |> URI.to_string()
        |> String.trim_trailing("/")
    end
  end

  defp normalize(_), do: ""
end
