import Config

if System.get_env("PHX_SERVER") do
  config :the_robot_learns, TheRobotLearnsWeb.Endpoint, server: true
end

config :the_robot_learns, :redis,
  uri: System.get_env("REDIS_URL") || "redis://localhost:6379/0",
  key_prefix: System.get_env("REDIS_KEY_PREFIX", "starter:")

parse_sso_domains = fn
  nil ->
    %{}

  "" ->
    %{}

  value ->
    value
    |> String.split(~r/[;\s]+/, trim: true)
    |> Enum.reduce(%{}, fn entry, acc ->
      case String.split(entry, ["=", ":"], parts: 2) do
        [domain, providers] ->
          provider_list =
            providers
            |> String.split(",", trim: true)
            |> Enum.map(&String.trim/1)
            |> Enum.reject(&(&1 == ""))

          Map.put(acc, domain |> String.trim() |> String.downcase(), provider_list)

        _ ->
          acc
      end
    end)
end

parse_domain_list = fn
  nil ->
    []

  "" ->
    []

  value ->
    value
    |> String.split(~r/[,\s;]+/, trim: true)
    |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
end

build_sso_domain_policies = fn domains, auto_approve_domains ->
  auto_approve = MapSet.new(auto_approve_domains)

  domains
  |> Enum.into(%{}, fn {domain, providers} ->
    {domain,
     %{
       providers: providers,
       auto_approve: MapSet.member?(auto_approve, "*") || MapSet.member?(auto_approve, domain)
     }}
  end)
end

# ── OpenTelemetry ────────────────────────────────────────────────
if otel_endpoint = System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT") do
  config :opentelemetry_exporter,
    otlp_protocol: :grpc,
    otlp_endpoint: otel_endpoint

  config :opentelemetry,
    span_processor: :batch,
    resource: %{
      "service.name" => System.get_env("OTEL_SERVICE_NAME") || "starter-backend",
      "service.version" => "0.1.0"
    }
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://user:pass@host/database
      """

  config :the_robot_learns, TheRobotLearns.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :the_robot_learns, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  guardian_secret =
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise """
      environment variable GUARDIAN_SECRET_KEY is missing.
      You can generate one by calling: mix guardian.gen.secret
      """

  config :the_robot_learns, TheRobotLearns.Guardian,
    issuer: "the_robot_learns",
    secret_key: guardian_secret

  config :the_robot_learns, :frontend_url, System.get_env("FRONTEND_URL")

  if sendgrid_key = System.get_env("SENDGRID_API_KEY") do
    config :noizu_sendgrid, api_key: sendgrid_key
  end

  config :the_robot_learns,
         :mail_from,
         {System.get_env("MAIL_FROM_NAME", "TheRobotLearns"),
          System.get_env("MAIL_FROM_ADDRESS", "noreply@starter.local")}

  # ── Storage (S3/MinIO) ──────────────────────────────────────────
  if s3_bucket = System.get_env("S3_BUCKET") do
    config :the_robot_learns, TheRobotLearns.Storage,
      bucket: s3_bucket,
      region: System.get_env("S3_REGION", "us-east-1"),
      host: System.get_env("S3_ENDPOINT"),
      scheme: System.get_env("S3_SCHEME", "https://"),
      access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")

    config :ex_aws,
      access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
      region: System.get_env("S3_REGION", "us-east-1"),
      s3: [
        scheme: System.get_env("S3_SCHEME", "https://"),
        host: System.get_env("S3_ENDPOINT"),
        region: System.get_env("S3_REGION", "us-east-1")
      ]
  end

  # ── SSO: OIDC ──────────────────────────────────────────────────
  if oidc_client_id = System.get_env("OIDC_CLIENT_ID") do
    config :openid_connect, :providers,
      default: [
        discovery_document_uri:
          System.get_env("OIDC_ISSUER") <> "/.well-known/openid-configuration",
        client_id: oidc_client_id,
        client_secret: System.get_env("OIDC_CLIENT_SECRET"),
        redirect_uri: System.get_env("OIDC_REDIRECT_URI") || "https://#{host}/auth/oidc/callback",
        response_type: "code",
        scope: "openid email profile"
      ]

    config :the_robot_learns, :oidc_enabled, true
  end

  # ── SSO: SAML ──────────────────────────────────────────────────
  saml_metadata =
    cond do
      value = System.get_env("SAML_IDP_METADATA") -> [metadata: value]
      value = System.get_env("SAML_IDP_METADATA_FILE") -> [metadata_file: value]
      true -> []
    end

  if saml_metadata != [] do
    sp_cert = System.get_env("SAML_SP_CERT", "") |> String.replace("\\n", "\n")
    sp_key = System.get_env("SAML_SP_KEY", "") |> String.replace("\\n", "\n")

    config :samly, Samly.Provider,
      service_providers: [
        %{
          id: "default",
          entity_id: System.get_env("SAML_SP_ENTITY_ID") || "https://#{host}",
          certfile_data: sp_cert,
          keyfile_data: sp_key
        }
      ],
      identity_providers: [
        %{
          id: "default",
          sp_id: "default",
          base_url: "https://#{host}/sso/saml",
          pre_session_create_pipeline: TheRobotLearnsWeb.SAMLHandler
        }
        |> Map.merge(Map.new(saml_metadata))
      ]

    config :the_robot_learns, :saml_enabled, true
  end

  # Invite-gated direct signup (email/password). Defaults ON in prod; set
  # REQUIRE_INVITE_FOR_SIGNUP=false to allow open (admin-approval pending) signup.
  config :the_robot_learns,
         :require_invite_for_signup,
         System.get_env("REQUIRE_INVITE_FOR_SIGNUP", "true") != "false"

  # ── SSO: Social OAuth (each enabled when *_CLIENT_ID is set) ──
  config :the_robot_learns, :sso_require_invite, System.get_env("SSO_REQUIRE_INVITE") == "true"
  sso_domains = parse_sso_domains.(System.get_env("SSO_DOMAINS"))
  sso_auto_approve_domains = parse_domain_list.(System.get_env("SSO_AUTO_APPROVE_DOMAINS"))
  config :the_robot_learns, :sso_domains, sso_domains
  config :the_robot_learns, :sso_auto_approve_domains, sso_auto_approve_domains

  config :the_robot_learns,
         :sso_domain_policies,
         build_sso_domain_policies.(sso_domains, sso_auto_approve_domains)

  oauth_providers = []

  oauth_providers =
    if google_id = System.get_env("GOOGLE_CLIENT_ID") do
      config :ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: google_id,
        client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

      config :the_robot_learns, :google_enabled, true
      [{:google, {Ueberauth.Strategy.Google, [default_scope: "email profile"]}} | oauth_providers]
    else
      oauth_providers
    end

  oauth_providers =
    if fb_id = System.get_env("FACEBOOK_CLIENT_ID") do
      config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
        client_id: fb_id,
        client_secret: System.get_env("FACEBOOK_CLIENT_SECRET")

      config :the_robot_learns, :facebook_enabled, true

      [
        {:facebook, {Ueberauth.Strategy.Facebook, [default_scope: "email,public_profile"]}}
        | oauth_providers
      ]
    else
      oauth_providers
    end

  oauth_providers =
    if gh_id = System.get_env("GITHUB_CLIENT_ID") do
      config :ueberauth, Ueberauth.Strategy.Github.OAuth,
        client_id: gh_id,
        client_secret: System.get_env("GITHUB_CLIENT_SECRET")

      config :the_robot_learns, :github_enabled, true
      [{:github, {Ueberauth.Strategy.Github, [default_scope: "user:email"]}} | oauth_providers]
    else
      oauth_providers
    end

  # LinkedIn SSO disabled — ueberauth_linkedin has incompatible oauth2 dep
  # oauth_providers =
  #   if li_id = System.get_env("LINKEDIN_CLIENT_ID") do
  #     config :ueberauth, Ueberauth.Strategy.LinkedIn.OAuth,
  #       client_id: li_id,
  #       client_secret: System.get_env("LINKEDIN_CLIENT_SECRET")
  #     config :the_robot_learns, :linkedin_enabled, true
  #     [{:linkedin, {Ueberauth.Strategy.LinkedIn, [default_scope: "r_liteprofile r_emailaddress"]}} | oauth_providers]
  #   else
  #     oauth_providers
  #   end

  if oauth_providers != [] do
    config :ueberauth, Ueberauth, providers: oauth_providers
  end

  config :the_robot_learns, TheRobotLearnsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
