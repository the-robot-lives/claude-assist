import Config

# ── Load local .env (does not override already-exported vars) ──
load_dotenv = fn path ->
  if File.exists?(path) do
    path
    |> File.stream!(:line, [:read])
    |> Enum.each(fn line ->
      line = line |> String.trim() |> String.trim_leading("\uFEFF")

      cond do
        line == "" ->
          :ok

        String.starts_with?(line, "#") ->
          :ok

        String.contains?(line, "=") ->
          [key, value] = String.split(line, "=", parts: 2)
          key = String.trim(key)

          value =
            value
            |> String.trim()
            |> String.trim_leading("\"")
            |> String.trim_trailing("\"")
            |> String.trim_leading("'")
            |> String.trim_trailing("'")

          if key != "" and System.get_env(key) in [nil, ""] do
            System.put_env(key, value)
          end

        true ->
          :ok
      end
    end)
  end
end

# Prefer hologram/.env, then parent styleguide/.env
load_dotenv.(Path.expand("../.env", __DIR__))
load_dotenv.(Path.expand("../../.env", __DIR__))

# ── Resolve OIDC credentials (same names as hologram-start-app + aliases) ──
env_first = fn keys ->
  Enum.find_value(keys, fn key ->
    case System.get_env(key) do
      nil -> nil
      "" -> nil
      v -> String.trim(v)
    end
  end)
end

# Prefer explicit OIDC_*, then START_APP_* (starter/hologram-start-app), then STYLEGUIDE_*
oidc_client_id =
  env_first.([
    "OIDC_CLIENT_ID",
    "START_APP_OIDC_CLIENT_ID",
    "STYLEGUIDE_OIDC_CLIENT_ID"
  ])

oidc_client_secret =
  env_first.([
    "OIDC_CLIENT_SECRET",
    "START_APP_OIDC_CLIENT_SECRET",
    "STYLEGUIDE_OIDC_CLIENT_SECRET"
  ])

# Default issuer matches terraform start-app-site.tf (auth.derobot.is / startapp)
default_startapp_issuer = "https://auth.derobot.is/application/o/startapp"

oidc_issuer =
  env_first.([
    "OIDC_ISSUER",
    "START_APP_OIDC_ISSUER",
    "STYLEGUIDE_OIDC_ISSUER"
  ]) ||
    if(is_binary(oidc_client_id) and oidc_client_id != "",
      do: default_startapp_issuer,
      else: nil
    )

oidc_redirect = env_first.(["OIDC_REDIRECT_URI", "STYLEGUIDE_OIDC_REDIRECT_URI", "START_APP_OIDC_REDIRECT_URI"])

# Diagnostic snapshot for /login (no secrets)
config :styleguide, :oidc_env_status, %{
  client_id_set: is_binary(oidc_client_id) and oidc_client_id != "",
  client_secret_set: is_binary(oidc_client_secret) and oidc_client_secret != "",
  issuer_set: is_binary(oidc_issuer) and oidc_issuer != "",
  redirect_set: is_binary(oidc_redirect) and oidc_redirect != "",
  dotenv_loaded:
    File.exists?(Path.expand("../.env", __DIR__)) or
      File.exists?(Path.expand("../../.env", __DIR__))
}

# ── SSO domain policies (optional) ─────────────────────────────
# SSO_DOMAINS="example.com=oidc,corp.com=oidc"
parse_sso_domains = fn
  nil ->
    %{}

  "" ->
    %{}

  raw when is_binary(raw) ->
    raw
    |> String.split([",", ";"], trim: true)
    |> Enum.reduce(%{}, fn part, acc ->
      case String.split(part, ["=", ":"], parts: 2) do
        [domain, providers] ->
          list =
            providers
            |> String.split(["|", ","], trim: true)
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))

          Map.put(acc, String.downcase(String.trim(domain)), list)

        _ ->
          acc
      end
    end)
end

# Default domain policy matches start-app-site.tf when SSO_DOMAINS unset
sso_domains_raw =
  case System.get_env("SSO_DOMAINS") do
    nil -> "noizu.com=oidc;therobotlives.com=oidc;derobot.is=oidc"
    "" -> "noizu.com=oidc;therobotlives.com=oidc;derobot.is=oidc"
    other -> other
  end

config :styleguide, :sso_domain_policies, parse_sso_domains.(sso_domains_raw)

# ── Authentik OIDC (auth.derobot.is / startapp by default) ─────
if is_binary(oidc_client_id) and oidc_client_id != "" do
  issuer =
    (oidc_issuer || default_startapp_issuer)
    |> String.trim()
    |> String.trim_trailing("/")

  discovery = issuer <> "/.well-known/openid-configuration"

  host = System.get_env("PHX_HOST") || System.get_env("HOST") || "localhost"
  port = System.get_env("PORT") || "4500"

  default_redirect =
    cond do
      is_binary(oidc_redirect) and oidc_redirect != "" ->
        oidc_redirect

      host in ["localhost", "127.0.0.1"] ->
        "http://#{host}:#{port}/auth/oidc/callback"

      true ->
        "https://#{host}/auth/oidc/callback"
    end

  config :openid_connect, :providers,
    default: [
      discovery_document_uri: discovery,
      client_id: oidc_client_id,
      client_secret: oidc_client_secret,
      redirect_uri: default_redirect,
      response_type: "code",
      scope: "openid email profile"
    ]

  config :styleguide, :oidc_enabled, true
  config :styleguide, :oidc_redirect_uri, default_redirect
  config :styleguide, :oidc_issuer, issuer
  config :styleguide, :cookie_secure, host not in ["localhost", "127.0.0.1"]
else
  config :styleguide, :oidc_enabled, false
  config :styleguide, :oidc_redirect_uri, nil
  config :styleguide, :oidc_issuer, nil
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :styleguide, StyleguideWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
