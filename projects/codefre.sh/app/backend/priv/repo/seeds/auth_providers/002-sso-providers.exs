require SeedHelper
import SeedHelper

alias Codefresh.Schema.Auth.Providers.Provider

oidc_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@OIDC")
saml_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@SAML")
google_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@Google")
facebook_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@Facebook")
github_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@GitHub")
linkedin_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@LinkedIn")

seed {"auth-provider:oidc", "1"} do
  Codefresh.Repo.insert!(%Provider{id: oidc_id, title: "OIDC", description: "OpenID Connect SSO"}, on_conflict: :nothing, conflict_target: :id)
end

seed {"auth-provider:saml", "1"} do
  Codefresh.Repo.insert!(%Provider{id: saml_id, title: "SAML", description: "SAML 2.0 SSO"}, on_conflict: :nothing, conflict_target: :id)
end

seed {"auth-provider:google", "1"} do
  Codefresh.Repo.insert!(%Provider{id: google_id, title: "Google", description: "Google OAuth"}, on_conflict: :nothing, conflict_target: :id)
end

seed {"auth-provider:facebook", "1"} do
  Codefresh.Repo.insert!(%Provider{id: facebook_id, title: "Facebook", description: "Facebook OAuth"}, on_conflict: :nothing, conflict_target: :id)
end

seed {"auth-provider:github", "1"} do
  Codefresh.Repo.insert!(%Provider{id: github_id, title: "GitHub", description: "GitHub OAuth"}, on_conflict: :nothing, conflict_target: :id)
end

seed {"auth-provider:linkedin", "1"} do
  Codefresh.Repo.insert!(%Provider{id: linkedin_id, title: "LinkedIn", description: "LinkedIn OAuth"}, on_conflict: :nothing, conflict_target: :id)
end
