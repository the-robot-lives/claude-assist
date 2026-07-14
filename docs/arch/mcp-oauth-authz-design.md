# MCP OAuth / AuthZ Design — tobor.locker

**Status:** Draft for review
**Date:** 2026-07-15
**Scope:** Authentication and authorization for the tobor MCP fleet
(`tobor.locker` + per-domain subdomains served by
`projects/NoizuPromptLingo/backend/`), covering three permission axes —
user entitlements, MCP client/server capability, and per-pairing grants —
plus on-behalf-of delegation (service → model/agent → user).

---

## 1. Current state (baseline)

| Aspect | Today |
|---|---|
| Server fleet | One Phoenix app, ~20 MCP servers routed by subdomain (`sessions.tobor.locker/mcp`, `organizations.tobor.locker/mcp`, …) via `Noizu.MCP.Transport.StreamableHTTP.Plug` |
| Client auth | Org-scoped MCP API key (bcrypt-hashed, shown once) → `POST /api/mcp/token` → **30-day HS256 JWT** |
| Signing | Shared `GUARDIAN_SECRET_KEY` (same secret as session JWTs) |
| Verification | `Noizu.MCP.Auth.CompoundJWTVerifier`: signature, issuer `tobor-locker`, expiry, `api_key_id` row still active |
| Audience binding | **None** — one token works on every subdomain |
| Delegation record | **None** — token identifies the API key/org, not the human, agent, or harness |
| Refresh | Manual re-mint on expiry |

### Problems this design must fix

1. **Symmetric shared secret.** Any service holding `GUARDIAN_SECRET_KEY` can mint arbitrary tokens; resource servers can forge as easily as verify.
2. **No audience.** A token leaked from a low-value MCP (e.g. read-only search) replays against `locker` or `sessions` at full power.
3. **30-day bearer lifetime.** Long-lived, unbound bearer tokens in `claude mcp add` command lines, frpc configs, and browser-controller configs.
4. **Flat identity.** `api_key_id` conflates the user, the agent harness, and the consent. No way to say "Claude may create sessions but only Keith may delete organizations," and audit logs can't distinguish "Keith did X" from "an agent acting for Keith did X."
5. **No pairing granularity.** Every client with the org key gets every tool on every server.

---

## 2. Goals & non-goals

**Goals**

- G1. Effective permission at every tool call = **intersection** of
  (user entitlements) ∩ (client/server capability) ∩ (pairing grant).
- G2. Every token carries the full **delegation chain** (`act` claim);
  impersonation is impossible by construction.
- G3. Per-resource-server audience binding; short-lived access tokens;
  instant central revocation of any axis.
- G4. Step-up / human approval for tools tagged destructive.
- G5. Incremental migration — current API-key clients keep working during rollout.
- G6. Stay inside the MCP spec's auth model (OAuth 2.1 resource servers,
  RFC 9728 protected-resource metadata) so third-party MCP clients
  (Claude Code, Claude.ai, inspector tools) interoperate without custom glue.

**Non-goals**

- Federated login / social IdP (single-operator infra; can be added behind the AS later).
- Offline sub-delegation between agents (Biscuit-style attenuation — revisit if needed, §9).
- Multi-tenant SaaS hardening beyond org boundaries already in the schema.

---

## 3. Authorization Server choice

Three candidates were evaluated. Recommendation: **build the AS into
tobor-locker (Phoenix)**, with Keycloak as the fallback if scope grows.

### Option A — Embed AS in tobor-locker (recommended)

The Phoenix app is already the token issuer (`iss: tobor-locker`), already
owns the user/org/API-key schema, and `noizu_mcp` already ships the
resource-server half (RFC 9728 plug, OAuth 2.1 client flow, compound
verifier). What's missing is the issuer half: authorize/token endpoints,
PKCE, token exchange, DCR, consent storage, JWKS.

- **For:** one deploy, one DB, Elixir end-to-end; consent UI lives next to
  the org/project data it must render ("allow *Claude Code* to call
  *Session.Create* on *noizu-infra*?"); RAR `authorization_details` are
  first-class Ecto schemas, not opaque strings shoved through a generic IdP;
  no new tier-2 service to operate.
- **Against:** you implement RFC 8693 token exchange, RFC 9396 RAR, and DCR
  yourself (~the four token-grant handlers plus consent CRUD; the crypto is
  all Joken/JOSE — no novel cryptography). Security review burden is yours.
- **Effort:** the spec surface needed is deliberately small — see §5. Existing
  Elixir libs (`boruta` for OAuth core, `openid_connect` for discovery
  shapes) cover parts; token exchange is a hand-rolled grant handler either way.

### Option B — Keycloak

- **For:** standard token exchange (first-class since KC 26), DCR, fine-grained
  authz built in; battle-tested; admin UI free.
- **Against:** a JVM stateful service at tier 2 (Postgres + Infinispan) in a
  cluster that is otherwise Elixir/Go; RAR support is partial; the pairing
  consent model would live half in Keycloak (clients, scopes) and half in
  tobor (which tools exist per server), forcing a sync job; user store is
  either duplicated or federated via a custom SPI (Java).
- **Verdict:** right answer if tobor ever serves third-party orgs at scale;
  overweight for a single-operator fleet whose entitlement data already
  lives in the tobor DB.

### Option C — Ory Hydra

- **For:** headless, lightweight, Go, login/consent delegated to your own app
  (which fits — tobor renders consent).
- **Against:** **no RFC 8693 token exchange** (open issue for years) — the
  on-behalf-of chain, the core of this design, would need to be faked with
  custom grant hooks; RAR unsupported. Disqualifying for this design.

---

## 4. Identity & policy model

### 4.1 Principals

| Principal | Example | Established by |
|---|---|---|
| **User** | `user:keith` | Password/passkey login at tobor-locker (existing Guardian session) |
| **Agent instance** | `agent:claude-code/sess-016Wwf…` | Asserted by the harness client at token exchange (actor token) |
| **MCP client (harness)** | `client:claude-code`, `client:remote-access`, `client:browser-controller` | DCR with signed software statement, or statically registered first-party clients |
| **MCP resource server** | `mcp:sessions`, `mcp:locker`, `mcp:organizations` | Rows in the `mcp_servers.ex` catalog → registered resources with canonical URIs `https://<sub>.tobor.locker/mcp` |
| **Service (downstream caller)** | `svc:tobornalp-backend` | client_credentials with its own key (K8s: project into pod via InfisicalSecret) |

### 4.2 The three axes as data

- **Axis 1 — user entitlements:** ReBAC tuples in the PDP (§6):
  org membership, project roles. *Source of truth: tobor DB, mirrored to SpiceDB.*
- **Axis 2 — capability:** per-server tool manifest (already in
  `mcp_servers.ex`) + per-client allowed grant types/resources set at
  registration. A harness registered as read-only can never request
  write tools regardless of user consent.
- **Axis 3 — pairing grant:** a stored consent record
  `(user, client_id, resource) → authorization_details` (§5.3). Created by
  the consent UI, referenced by every token minted for that pairing,
  revocable independently.

Effective permission = PDP check that consults all three at call time (§6.3).

---

## 5. Protocol surface

### 5.1 Endpoints (all on `https://tobor.locker`)

```
GET  /.well-known/oauth-authorization-server      # RFC 8414 AS metadata
GET  /.well-known/jwks.json                       # rotating EdDSA/RS256 keys
GET  https://<sub>.tobor.locker/.well-known/oauth-protected-resource
                                                  # RFC 9728 (per subdomain; plug exists)
GET  /oauth/authorize                             # code + PKCE, renders consent
POST /oauth/token                                 # grants: authorization_code,
                                                  #   refresh_token, client_credentials,
                                                  #   urn:ietf:params:oauth:grant-type:token-exchange
POST /oauth/register                              # RFC 7591 DCR (software_statement optional)
POST /oauth/revoke                                # RFC 7009 (kills chain, see §5.5)
POST /oauth/device                                # (phase 3) CIBA-lite approval for step-up
```

Signing moves from shared HS256 to **asymmetric keys (EdDSA preferred,
RS256 for client compat) published at JWKS**, with kid-based rotation.
`GUARDIAN_SECRET_KEY` stays for legacy session cookies only.

### 5.2 Token schemas

**User access token** (post-login, harness has not yet entered the picture):

```json
{
  "iss": "https://tobor.locker",
  "sub": "user:keith",
  "aud": "https://tobor.locker",           
  "exp": 1752600000, "iat": 1752599700, "jti": "…",
  "scope": "openid mcp.exchange",
  "org": "noizu-labs"
}
```

**Delegated MCP access token** (what actually hits an MCP server) — minted
by token exchange, `subject_token` = user token (or refresh-derived),
`actor_token` = harness client assertion:

```json
{
  "iss": "https://tobor.locker",
  "sub": "user:keith",
  "act": {
    "sub": "client:claude-code",
    "agent": "agent:claude-code/sess-016Wwf5k"
  },
  "aud": "https://sessions.tobor.locker/mcp",
  "exp": 1752600300,                        
  "iat": 1752600000, "jti": "…",
  "cnf": { "jkt": "<DPoP key thumbprint>" },
  "grant_id": "pg_8f3c…",                   
  "authorization_details": [
    {
      "type": "mcp_tool_grant",
      "server": "sessions",
      "tools": ["Session.Create", "Session.Update", "Session.Get"],
      "constraints": { "project": "noizu-infra" }
    }
  ]
}
```

Notes:
- `exp − iat` = **5 minutes** for MCP access tokens. The harness refreshes
  silently; humans never see these.
- `aud` is the RFC 8707 `resource` the client requested; the
  `CompoundJWTVerifier` on each subdomain rejects any other audience.
- `act` nests on further hops (RFC 8693): if `mcp:sessions` calls
  `mcp:locker` on-behalf-of, it exchanges again and the new token carries
  `act: { sub: "mcp:sessions", act: { sub: "client:claude-code", … } }`.
- `grant_id` points at the pairing-grant row — revoking the row kills every
  live token derived from it at the PDP even before expiry.
- `cnf.jkt` = DPoP binding (phase 3; omit in phase 2).

**Service token** (machine-only, no user): client_credentials, `sub` =
`svc:…`, no `act`, RAR limited by the client's registration.

**Elevation token** (step-up, §7): single-use (`jti` burned on first use),
60-second expiry, `authorization_details` naming exactly one tool call,
`amr: ["hitl"]`.

### 5.3 Pairing grant record (Ecto schema, tobor DB)

```elixir
schema "mcp_pairing_grants" do
  field :grant_id, :string            # pg_…
  belongs_to :user, User
  field :client_id, :string           # client:claude-code
  field :resource, :string            # https://sessions.tobor.locker/mcp
  field :authorization_details, {:array, :map}   # RAR objects, §5.2
  field :status, Ecto.Enum, values: [:active, :revoked]
  field :expires_at, :utc_datetime    # optional standing-consent TTL
  timestamps()
end
```

Consent UI = a page in tobor-locker listing requested `authorization_details`
diffed against any existing grant (incremental consent). The UI can render
human names because the tool catalog lives in the same app.

### 5.4 Grant flows

**First connect (human present):**

```mermaid
sequenceDiagram
  participant U as User (browser)
  participant H as Harness (Claude Code)
  participant AS as tobor.locker AS
  participant RS as sessions.tobor.locker

  H->>RS: MCP request, no token
  RS-->>H: 401 + WWW-Authenticate (RFC 9728 PRM URL)
  H->>AS: GET AS metadata; POST /oauth/register (DCR, if new)
  H->>U: open /oauth/authorize?resource=…&authorization_details=…&code_challenge=…
  U->>AS: login (existing session) → consent screen → approve
  AS-->>H: code → POST /oauth/token (PKCE) → refresh + user-grade token
  H->>AS: POST /oauth/token grant_type=token-exchange<br/>subject=user token, actor=client assertion,<br/>resource=https://sessions…/mcp
  AS-->>H: 5-min delegated access token (act chain, RAR, aud)
  H->>RS: MCP request + Bearer
  RS->>RS: verify sig/aud/exp → PDP check (§6.3) → execute
```

**Steady state:** harness holds one refresh token per pairing; every ~4 min
it token-exchanges for a fresh audience-bound access token. Headless
clients (frpc remote-access, browser-controller, cron agents) hold a
long-lived refresh token bound to their DCR client — never a long-lived
access token.

### 5.5 Revocation semantics

| Revoke | Effect |
|---|---|
| Pairing grant row | All tokens with that `grant_id` fail PDP checks immediately; refresh refuses |
| Client registration | Every pairing for that client dies |
| User session / password reset | All refresh tokens for `sub` invalidated |
| One `jti` (rare) | Denylist with TTL = remaining token life (5 min max — cheap) |

Because access tokens live 5 minutes, the PDP `grant_id` check is the only
online check needed; no full token-introspection round trip.

---

## 6. Policy Decision Point — SpiceDB

Deploy SpiceDB (tier 1, `data-ns`, Postgres datastore on the existing
TimescaleDB instance or its own small PG) as the single evaluator of the
three-axis intersection.

### 6.1 Schema

```zed
definition user {}

definition client {}                      // harness registrations

definition agent {
  relation instance_of: client
}

definition organization {
  relation admin: user
  relation member: user
  permission administer = admin
  permission belong = member + admin
}

definition project {
  relation org: organization
  relation maintainer: user
  relation reader: user
  permission write = maintainer + org->administer
  permission read  = reader + write + org->belong
}

definition mcp_server {
  relation org: organization
  // which clients are capable/trusted to talk to this server at all (axis 2)
  relation allowed_client: client
}

definition tool {
  relation server: mcp_server
  // axis 1: which users may invoke this tool directly, via role sugar
  relation invoker: user | organization#member | organization#admin
  // sensitivity gate (§7): tools with this set require an elevation token
  relation requires_approval_from: user
  permission invoke = invoker & server->org->belong
}

definition pairing_grant {
  relation grantor: user                  // the consenting user
  relation client: client                 // the harness
  relation covers_tool: tool              // expanded from RAR at grant time
  relation status_active: user:*          // presence = active; delete on revoke
}
```

### 6.2 Tuple mirroring

- Org/project membership tuples are written by the existing tobor Ecto
  contexts (a thin `Noizu.AuthZ` module wrapping the SpiceDB gRPC client;
  write-through on membership changes, plus a nightly reconcile job).
- `mcp_server`/`tool` tuples are seeded from `mcp_servers.ex` at deploy
  (mix task), so the catalog stays the single source of truth.
- `pairing_grant` tuples are written when a consent is approved: one
  `covers_tool` tuple per tool named in the RAR.

### 6.3 The check (per tool call, in the MCP plug pipeline)

After JWT verification, the server asks SpiceDB (single batched
CheckBulk, ~1 ms in-cluster):

```
1. tool:sessions/Session.Create  invoke   user:keith          # axis 1
2. mcp_server:sessions           allowed_client  client:claude-code   # axis 2
3. pairing_grant:pg_8f3c         covers_tool     tool:sessions/Session.Create
   AND pairing_grant:pg_8f3c     status_active   (exists)     # axis 3
```

All three must pass. Token `authorization_details` are treated as a *cache
hint* for fast local pre-filtering, but SpiceDB is authoritative — this is
what makes revocation instant despite stateless JWTs.

**Constraint enforcement** (e.g. `{"project": "noizu-infra"}`): the plug
resolves the request's target object and checks
`project:noizu-infra write user:keith` (or `read`) as tuple #4 when the RAR
carries a project constraint. Tool handlers receive the verified context
struct (`%Noizu.MCP.CallerContext{user, act_chain, grant_id, constraints}`)
and must scope queries by it — same pattern as today's `api_key_id → org`
scoping, one level finer.

**Failure mode:** SpiceDB unreachable → fail closed for `write`-class
tools, fail open **only** for tools explicitly tagged `public_read` in the
catalog. (Fleet is first-party; availability risk is acceptable at tier 1
with 2 replicas.)

---

## 7. Step-up / human-in-the-loop

Tools are tagged in the catalog: `:safe`, `:sensitive`, `:destructive`.

- `:safe` — normal flow.
- `:sensitive` — allowed if the pairing grant explicitly named the tool
  (no wildcard expansion into sensitive tools at consent time).
- `:destructive` (e.g. `Organization.Delete`, locker secret reads) — the
  MCP server responds with an RFC 9470-style challenge:

```json
{ "error": "insufficient_authorization",
  "error_description": "tool requires elevation",
  "elevation_uri": "https://tobor.locker/oauth/device?txn=…" }
```

The harness surfaces the URI; the human approves in a browser (or, phase 4,
a push notification via ntfy/tobornalp frontend). Approval mints the
single-use elevation token (§5.2) naming exactly that tool + argument hash.
The retried call presents both tokens. Audit row records `amr: hitl` and
the approving session.

This turns "the model shouldn't push the big red button alone" from a
prompt-level convention into protocol.

---

## 8. Migration plan

**Phase 0 — key hygiene (independent, do first):**
switch JWT signing to EdDSA + JWKS; add `aud` claim = requesting subdomain
to the *existing* `/api/mcp/token` mint; verifier enforces `aud` with a
grace flag for legacy tokens. Drop TTL 30d → 7d. No client changes except
re-mint cadence.

**Phase 1 — AS core:** implement `/oauth/authorize` (PKCE) +
`authorization_code`/`refresh_token` grants + consent UI + pairing-grant
schema. First-party clients (Claude Code via native MCP OAuth support)
switch over; API-key path still works.

**Phase 2 — delegation:** token-exchange grant + `act` chains + DCR.
Headless clients (remote-access, browser-controller) re-register via DCR
and move to refresh-token flow. Access-token TTL → 5 min.

**Phase 3 — PDP:** deploy SpiceDB, seed tuples, enable the three-axis
check in `CompoundJWTVerifier`'s successor (`Noizu.MCP.Auth.PolicyVerifier`).
Legacy API-key JWTs get a synthetic full-org pairing grant so behavior is
unchanged until keys are retired. Add DPoP.

**Phase 4 — retire API keys + step-up:** disable `/api/mcp/token` for new
mints; elevation flow for `:destructive` tools; push-approval channel.

Each phase is independently shippable and reversible; the verifier accepts
both token generations until phase 4.

---

## 9. Alternatives (recorded for posterity)

- **GNAP (RFC 9635):** conceptually the best fit (agents as first-class
  parties, incremental grants) but no ecosystem, and MCP standardized on
  OAuth 2.1 — rejected.
- **Biscuit/Macaroon attenuation:** offline sub-delegation and mechanical
  intersection-by-caveat are elegant; loses central revocation and OAuth
  interop with third-party MCP clients. Revisit only if agents must
  delegate to sub-agents without an AS round trip.
- **UCAN:** same niche as Biscuits, weaker tooling — rejected.
- **ReBAC-only with opaque tokens:** simpler, but every third-party MCP
  client expects OAuth bearer semantics per the MCP spec; and opaque tokens
  force introspection round trips that the 5-min JWT + PDP design avoids.
  The chosen design is effectively this model *plus* standards-compliant
  token envelopes.
- **Keycloak / Ory Hydra as AS:** §3 — Hydra disqualified (no token
  exchange); Keycloak held in reserve if third-party org tenancy arrives.

## 10. Open questions

1. Does Claude Code's native MCP OAuth flow pass `authorization_details`
   (RAR) through, or only `scope`? If scope-only, encode the pairing grant
   server-side keyed by `(client_id, resource)` and keep RAR internal —
   design already tolerates this (`grant_id` is the join key, not the RAR).
2. SpiceDB datastore: shared TimescaleDB instance vs dedicated small PG —
   lean dedicated (different tuning profile, avoids coupling migrations).
3. Should `agent:` instance IDs (per-session) be recorded as SpiceDB tuples
   or only in the `act` claim + audit log? Current answer: audit-only;
   policy binds to `client:` (the harness), instances are ephemeral.
4. Elevation approval transport for headless/phone contexts — tobornalp
   frontend push vs ntfy vs email magic link.
