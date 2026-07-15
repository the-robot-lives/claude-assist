defmodule Styleguide.Auth do
  @moduledoc """
  Authentik (OIDC) helpers for the styleguide viewer.

  Mirrors hologram-start-app SSO discovery flags and domain policies, without a
  user database — successful OIDC claims become a signed-in cookie session.
  """

  @cookie_email "sg-user-email"
  @cookie_name "sg-user-name"
  @cookie_sub "sg-user-sub"
  @cookie_max_age 60 * 60 * 24 * 7

  def cookie_email, do: @cookie_email
  def cookie_name, do: @cookie_name
  def cookie_sub, do: @cookie_sub
  def cookie_max_age, do: @cookie_max_age

  @doc "True when OIDC_CLIENT_ID / runtime config enabled Authentik SSO."
  def oidc_enabled? do
    Application.get_env(:styleguide, :oidc_enabled, false) == true
  end

  @doc "OpenID Connect provider config map (or nil)."
  def oidc_config do
    case Application.get_env(:openid_connect, :providers) do
      nil ->
        nil

      providers ->
        case Keyword.get(providers, :default) do
          nil -> nil
          conf when is_list(conf) -> Map.new(conf)
          conf when is_map(conf) -> conf
          _ -> nil
        end
    end
  end

  @doc """
  Non-secret setup status for the login page.

  Keys: enabled, client_id_set, client_secret_set, issuer_set, redirect_uri, issuer, dotenv_loaded, missing
  """
  def config_status do
    env = Application.get_env(:styleguide, :oidc_env_status, %{})
    enabled = oidc_enabled?()

    client_id_set = Map.get(env, :client_id_set, false)
    client_secret_set = Map.get(env, :client_secret_set, false)
    issuer_set = Map.get(env, :issuer_set, false) or is_binary(Application.get_env(:styleguide, :oidc_issuer))
    dotenv_loaded = Map.get(env, :dotenv_loaded, false)

    missing =
      []
      |> then(fn m -> if issuer_set, do: m, else: ["OIDC_ISSUER" | m] end)
      |> then(fn m -> if client_id_set, do: m, else: ["OIDC_CLIENT_ID" | m] end)
      |> then(fn m -> if client_secret_set, do: m, else: ["OIDC_CLIENT_SECRET" | m] end)
      |> Enum.reverse()

    %{
      enabled: enabled,
      client_id_set: client_id_set,
      client_secret_set: client_secret_set,
      issuer_set: issuer_set,
      dotenv_loaded: dotenv_loaded,
      missing: missing,
      missing_text: Enum.join(missing, ", "),
      issuer: Application.get_env(:styleguide, :oidc_issuer) || "",
      redirect_uri:
        Application.get_env(:styleguide, :oidc_redirect_uri) ||
          "http://localhost:4500/auth/oidc/callback",
      has_missing: missing != []
    }
  end

  @doc """
  SSO catalog for the login UI.

  `%{enabled: bool, providers: ["oidc"], domain_policies: %{domain => [providers]}}`
  """
  def sso_catalog do
    providers = if oidc_enabled?(), do: ["oidc"], else: []
    status = config_status()

    %{
      enabled: providers != [],
      providers: providers,
      domain_policies: domain_policies(),
      label: sso_label("oidc"),
      path: sso_path("oidc"),
      status: status
    }
  end

  def sso_path("oidc"), do: "/auth/oidc"
  def sso_path(_), do: "/auth/oidc"

  def sso_label("oidc"), do: "Sign in with SSO"
  def sso_label(_), do: "Sign in with SSO"

  @doc "Providers allowed for an email domain that are also enabled."
  def matching_sso_providers(email, catalog \\ nil) do
    catalog = catalog || sso_catalog()
    domain = email_domain(email)
    policies = catalog.domain_policies || %{}

    domain_providers =
      case Map.get(policies, domain) do
        nil ->
          # No domain policy: if OIDC is on, all domains may use it (Authentik gate)
          if catalog.enabled, do: catalog.providers, else: []

        list when is_list(list) ->
          list

        %{providers: list} when is_list(list) ->
          list

        %{"providers" => list} when is_list(list) ->
          list

        _ ->
          []
      end

    Enum.filter(domain_providers, &(&1 in catalog.providers))
  end

  def email_domain(email) when is_binary(email) do
    email
    |> String.trim()
    |> String.downcase()
    |> String.split("@")
    |> List.last()
  end

  def email_domain(_), do: ""

  @doc "Current user map from Hologram server cookies, or nil."
  def current_user(server) do
    email = Hologram.Server.get_cookie(server, @cookie_email)

    if is_binary(email) and email != "" do
      %{
        email: email,
        name: Hologram.Server.get_cookie(server, @cookie_name) || email,
        sub: Hologram.Server.get_cookie(server, @cookie_sub)
      }
    else
      nil
    end
  end

  def put_user_cookies(conn, %{email: email} = user) do
    name = Map.get(user, :name) || email
    sub = Map.get(user, :sub) || ""
    opts = cookie_opts()

    conn
    |> Plug.Conn.put_resp_cookie(@cookie_email, email, opts)
    |> Plug.Conn.put_resp_cookie(@cookie_name, name, opts)
    |> Plug.Conn.put_resp_cookie(@cookie_sub, sub, opts)
  end

  @doc "Write identity into Hologram cookies (readable by Hologram pages / middleware)."
  def put_user_cookies_hologram(server, %{email: email} = user) do
    name = Map.get(user, :name) || email
    sub = to_string(Map.get(user, :sub) || "")
    opts = hologram_cookie_opts()

    server
    |> Hologram.Server.put_cookie(@cookie_email, email, opts)
    |> Hologram.Server.put_cookie(@cookie_name, name, opts)
    |> Hologram.Server.put_cookie(@cookie_sub, sub, opts)
  end

  def clear_user_cookies(conn) do
    opts = Keyword.put(cookie_opts(), :max_age, 0)

    conn
    |> Plug.Conn.put_resp_cookie(@cookie_email, "", opts)
    |> Plug.Conn.put_resp_cookie(@cookie_name, "", opts)
    |> Plug.Conn.put_resp_cookie(@cookie_sub, "", opts)
  end

  def clear_user_cookies_hologram(server) do
    opts = hologram_cookie_opts() |> Keyword.put(:max_age, 0)

    server
    |> Hologram.Server.put_cookie(@cookie_email, "", opts)
    |> Hologram.Server.put_cookie(@cookie_name, "", opts)
    |> Hologram.Server.put_cookie(@cookie_sub, "", opts)
  end

  defp cookie_opts do
    [
      max_age: @cookie_max_age,
      http_only: false,
      same_site: "Lax",
      secure: cookie_secure?(),
      path: "/"
    ]
  end

  defp hologram_cookie_opts do
    # Must use secure: false on http://localhost or the browser drops the cookie.
    [
      max_age: @cookie_max_age,
      http_only: false,
      path: "/",
      same_site: :lax,
      secure: cookie_secure?()
    ]
  end

  defp cookie_secure? do
    Application.get_env(:styleguide, :cookie_secure, false)
  end

  defp domain_policies do
    Application.get_env(:styleguide, :sso_domain_policies, %{})
  end
end
