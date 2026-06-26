require SeedHelper
import SeedHelper

dir = Path.dirname(__ENV__.file)
Code.eval_file("#{dir}/prod-seeds.exs")

alias Therobotsdayjob.Schema.Users.User
alias Therobotsdayjob.Schema.Organizations.Organization
alias Therobotsdayjob.Schema.Organizations.Membership
alias Therobotsdayjob.Schema.Organizations.InviteToken
alias Therobotsdayjob.Schema.Users.Credentials.UserCredential
alias Therobotsdayjob.Schema.Versioned.Names.Name
alias Therobotsdayjob.Schema.Versioned.Descriptions.Description

admin_id = UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin")
dev_org_id = UUID.uuid5(:oid, "Therobotsdayjob.Dev.Organization")
login_provider_id = UUID.uuid5(:oid, "Therobotsdayjob.Schema.Auth.Providers.Provider@Login")

seed {"dev:admin-name", "1"} do
  Therobotsdayjob.Repo.insert!(
    %Name{id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin.Name"), first: "Admin", last: "User"},
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-description", "1"} do
  Therobotsdayjob.Repo.insert!(
    %Description{
      id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin.Description"),
      title: "Admin",
      body: "Default development admin user"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-user", "1"} do
  Therobotsdayjob.Repo.insert!(
    %User{
      id: admin_id,
      user_name: "admin",
      handle: "admin",
      name_id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin.Name"),
      description_id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin.Description"),
      email: "admin@starter.local",
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      status: :active,
      verified: true,
      flagged: false
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-credential", "1"} do
  Therobotsdayjob.Repo.insert!(
    %UserCredential{
      id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.Admin.Credential"),
      user_id: admin_id,
      auth_provider_id: login_provider_id,
      status: :active,
      settings: %{
        "email" => "admin@starter.local",
        "password" => Bcrypt.hash_pwd_salt("password123")
      },
      state: %{},
      fingerprint: "dev-admin-login"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:organization", "1"} do
  Therobotsdayjob.Repo.insert!(
    %Organization{
      id: dev_org_id,
      slug: "dev",
      name: "Dev Org"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-membership", "1"} do
  # Memberships moved to PBAC scoped memberships (see changelog 021-migrate-memberships-to-pbac).
  {:ok, _} =
    Therobotsdayjob.Authz.ScopedMemberships.add_member(
      "organization",
      dev_org_id,
      admin_id,
      "owner",
      admin_id
    )
end

seed {"dev:bootstrap-invite", "1"} do
  raw_token = "dev-bootstrap-invite-token-do-not-use-in-prod"
  token_hash = Bcrypt.hash_pwd_salt(raw_token)
  key_prefix = String.slice(raw_token, 0, 8)

  Therobotsdayjob.Repo.insert!(
    %InviteToken{
      id: UUID.uuid5(:oid, "Therobotsdayjob.Dev.BootstrapInvite"),
      organization_id: dev_org_id,
      created_by_user_id: admin_id,
      token_hash: token_hash,
      key_prefix: key_prefix,
      max_uses: nil,
      uses: 0,
      revoked: false
    },
    on_conflict: :nothing,
    conflict_target: :id
  )

  IO.puts("""

  ╔══════════════════════════════════════════════════════════════╗
  ║  Dev Bootstrap Invite Token                                  ║
  ║  #{raw_token}  ║
  ║  Use this token to register additional users in dev mode.   ║
  ╚══════════════════════════════════════════════════════════════╝

  Dev admin credentials:
    Email:    admin@starter.local
    Password: password123
  """)
end

seed {"dev:admin-magic-link-token", "1"} do
  {:ok, admin_ref} = Therobotsdayjob.Users.User.ref(admin_id)
  context = Noizu.Context.system()

  token =
    SmartToken.new(%{
      type: :magic_link,
      resource: {:bind, :recipient},
      context: {:bind, :recipient},
      scope: {:auth, :magic_link},
      validity_period: {:unbound, {:relative, [{:day, 365}]}},
      extended_info: %{multi_use: true, limit: 1000}
    })
    |> SmartToken.bind!(%{recipient: admin_ref}, context)

  encoded_key = SmartToken.encoded_key(token)

  IO.puts("""

  ╔══════════════════════════════════════════════════════════════╗
  ║  Dev Magic Link Token (admin)                                ║
  ╚══════════════════════════════════════════════════════════════╝

  Token: #{encoded_key}
  URL:   http://localhost:3000/auth/verify?token=#{encoded_key}
  """)
end
