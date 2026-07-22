dir = Path.dirname(__ENV__.file)
Code.eval_file("#{dir}/prod-seeds.exs")

require SeedHelper
import SeedHelper

alias Codefresh.Schema.Users.User
alias Codefresh.Schema.Organizations.Organization
alias Codefresh.Accounts.InviteToken
alias Codefresh.Schema.Users.Credentials.UserCredential
alias Codefresh.Schema.Versioned.Names.Name
alias Codefresh.Schema.Versioned.Descriptions.Description

admin_id = UUID.uuid5(:oid, "Codefresh.Dev.Admin")
dev_org_id = UUID.uuid5(:oid, "Codefresh.Dev.Organization")
login_provider_id = UUID.uuid5(:oid, "Codefresh.Schema.Auth.Providers.Provider@Login")

seed {"dev:admin-name", "1"} do
  Codefresh.Repo.insert!(
    %Name{id: UUID.uuid5(:oid, "Codefresh.Dev.Admin.Name"), first: "Admin", last: "User"},
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-description", "1"} do
  Codefresh.Repo.insert!(
    %Description{
      id: UUID.uuid5(:oid, "Codefresh.Dev.Admin.Description"),
      title: "Admin",
      body: "Default development admin user"
    },
    on_conflict: :nothing,
    conflict_target: :id
  )
end

seed {"dev:admin-user", "1"} do
  Codefresh.Repo.insert!(
    %User{
      id: admin_id,
      user_name: "admin",
      handle: "admin",
      name_id: UUID.uuid5(:oid, "Codefresh.Dev.Admin.Name"),
      description_id: UUID.uuid5(:oid, "Codefresh.Dev.Admin.Description"),
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
  Codefresh.Repo.insert!(
    %UserCredential{
      id: UUID.uuid5(:oid, "Codefresh.Dev.Admin.Credential"),
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
  Codefresh.Repo.insert!(
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
  {:ok, _membership} =
    Codefresh.Authz.ScopedMemberships.add_member(
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
  expires_at = DateTime.utc_now() |> DateTime.add(365 * 24 * 60 * 60, :second) |> DateTime.truncate(:second)

  Codefresh.Repo.insert!(
    %InviteToken{
      id: UUID.uuid5(:oid, "Codefresh.Dev.BootstrapInvite"),
      organization_id: dev_org_id,
      invited_by_user_id: admin_id,
      email: nil,
      role: "viewer",
      token_hash: token_hash,
      key_prefix: key_prefix,
      expires_at: expires_at,
      max_uses: 100,
      use_count: 0,
      revoked_at: nil,
      metadata: %{"seed" => "dev-bootstrap"}
    },
    on_conflict:
      {:replace,
       [
         :invited_by_user_id,
         :email,
         :role,
         :token_hash,
         :key_prefix,
         :expires_at,
         :max_uses,
         :use_count,
         :revoked_at,
         :metadata,
         :updated_at
       ]},
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
  {:ok, admin_ref} = Codefresh.Users.User.ref(admin_id)
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
