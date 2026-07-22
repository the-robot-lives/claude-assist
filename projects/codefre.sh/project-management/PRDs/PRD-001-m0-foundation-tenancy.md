---
id: PRD-001
title: "M0 — Foundation & Contract Freeze (tenancy, API tokens, platform stand-up)"
status: draft
milestone: M0
stories: [US-039, US-040, US-096, US-097]
created: 2026-07-22
updated: 2026-07-22
---

# PRD-001: M0 — Foundation & Contract Freeze

**Version**: 1.0 · **Status**: Draft · **Author**: npl-prd-editor
**Roadmap ref**: `project-management/roadmap/01-M0-foundation.md`
**Plan ref**: `docs/IMPLEMENTATION-PLAN.md` (§6 Stage 0 checklist, §7 DoD, §15 seqs 1–4, Stage 0.5)
**Data-model ref**: `docs/arch/data-model.md` (§4 tenancy, §14.1 api_tokens, §14.8 audit_events, §14.16 invite_tokens)
**Screens**: `project-management/screens/24-organization-settings.md`, `37-api-token-management.md`
**Backend root**: `app/backend/` · **Frontend root**: `app/frontend/`

---

## 0. Read this first — verified current state

Per the roadmap entry criteria and `IMPLEMENTATION-PLAN.md` §3, the following **already exist** on
the current checkout and must be **reused, not rebuilt**:

- Contexts `Codefresh.Accounts` and `Codefresh.Organizations`; `AuthController`; the login/signup
  flow; the **invite-token system** (`invite_tokens` table §14.16, `Codefresh.Accounts.register_user_with_invite/2`).
- Signup is **invite-only** — a user cannot register without a valid `invite_tokens` row.

**Genuinely net-new in M0:** the `api_tokens` table + context + bearer-auth plug (US-096/097); the
membership **invite/add** surface (US-040) layered on the existing invite-token mechanism; the
`audit_events` table (forward-loaded — see §15 conflict C4); and all Stage-0 platform plumbing
(migrations execution, Oban, CI, Cypress, outbound OTel, OpenAPI spex, auth-UI card, audit ingest).
Any later instruction contradicting the above should be reconciled before implementation.

---

## 1. Overview

M0 makes the platform **buildable** and its interfaces **frozen**. Two lanes:

- **Lane A (this PRD's stories + platform work):** execute the staged migrations, stand up Oban, CI,
  Cypress, outbound OTel, OpenAPI spex, and ship the tenancy surfaces — org creation (US-039),
  member invite (US-040), and API-token issue/revoke/rotate (US-096/097, forward-loaded because the
  CLI-login contract in M7 consumes them).
- **Lane B (contract freeze, no stories):** version and merge the four contracts every later
  milestone consumes.

### Goals

1. Login → create org → invite member → issue/revoke/rotate API token works end-to-end, exercised in CI.
2. All staged migrations execute against dev + CI DBs; `mix test` green; Oban running; ≥1 Cypress smoke passing.
3. The four contracts (OpenAPI, YAML script schema, rubric DSL JSON-schema, OTLP receiver) frozen, versioned, merged.
4. Every new controller mutation emits an `audit_events` row and an OTel span (per DoD §7-10).

### Non-Goals (deferred)

- First-user signup UX / personal-org auto-creation (Wave 2). Org billing, org deletion (Wave 3).
- Email-based invite accept-link flow; role change / member removal UI (Wave 2).
- Fine-grained per-resource token ACLs, OAuth client-credentials grant, token introspection (Wave 3).
- SSO/SCIM (Wave 3). CLI itself (M7 — this PRD only freezes the token contract it will consume).

---

## 2. Background & current state

`Codefresh.Accounts` owns users + invite-token redemption; `Codefresh.Organizations` owns
organizations + memberships. Auth is session/JWT for the browser. M0 adds a **second** credential
type — bearer API tokens — for SDK/CLI, and the member-invite surface on top of invite tokens.
`data-model.md` §10 sequences `create_organizations` (orgs + memberships) as Wave-1 migration #2;
`api_tokens` is §14.1 / seq 17a; `invite_tokens` is §14.16 (already migrated,
`20260421000050_create_invite_tokens.exs`).

---

## 3. Data model (authoritative field names from `data-model.md` — do not diverge)

### 3.1 `organizations` (exists — §4)
`id uuid pk`, `slug citext NOT NULL UNIQUE`, `name text NOT NULL`, `settings jsonb NOT NULL '{}'`,
`inserted_at`, `updated_at`. Slug is URL-safe and **globally unique**.

### 3.2 `memberships` (exists — §4)
`id uuid pk`, `organization_id uuid NOT NULL → organizations (cascade)`,
`user_id uuid NOT NULL → users (cascade)`, `role text NOT NULL` (enum `:owner | :admin | :editor | :viewer`),
`inserted_at`, `updated_at`. Unique `(organization_id, user_id)`; index `(user_id)`.

### 3.3 `invite_tokens` (exists — §14.16) — the mechanism behind US-040 "pending invite"
Org-scoped, email-bound invite = `organization_id` set + `email` set + `role`. Columns of note:
`token_hash bytea`, `key_prefix text` (first 8 chars, indexed), `role text`
(`:owner|:admin|:editor|:viewer|:ci`), `expires_at`, `max_uses int default 1`, `use_count int`,
`revoked_at`, `metadata jsonb`. Partial-unique `(organization_id, email) WHERE email IS NOT NULL AND
revoked_at IS NULL AND use_count < max_uses` prevents duplicate pending invites. Redemption is
transactional (`Ecto.Multi`): validate → insert user → resolve/create org → insert membership →
increment `use_count`.

### 3.4 `api_tokens` (**net-new** — §14.1)
```
id                  uuid pk default gen_random_uuid()
organization_id     uuid NOT NULL  -- FK organizations
name                text NOT NULL  -- user-visible label
token_hash          bytea NOT NULL -- bcrypt/argon2 of raw token
key_prefix          text NOT NULL  -- first 8 chars of raw token, support lookup
role                text NOT NULL  -- enum :owner|:admin|:editor|:viewer|:ci
created_by_user_id  uuid           -- nullable
expires_at          utc_datetime   -- nullable = non-expiring
last_used_at        utc_datetime   -- updated on authenticated request
revoked_at          utc_datetime   -- set on revoke
inserted_at / updated_at utc_datetime NOT NULL
```
Unique `(token_hash)`, `(organization_id, name)`. Raw token shown once at creation; never persisted
plaintext. Migration forward-loaded from seq 17a into the M0 sequence.

### 3.5 `audit_events` (**forward-loaded** from Wave 3 §14.8 — see conflict C4)
Append-only. `id`, `organization_id`, `actor_user_id` (nullable), `action text` (e.g.
`membership_created`, `token_created`, `token_revoked`, `token_rotated`, `organization_created`),
`subject_type text` (`membership`, `token`, `organization`), `subject_id uuid`, `subject_slug text`,
`diff jsonb`, `metadata jsonb '{}'` (IP, user agent, request id), `timestamp timestamptz`,
`inserted_at`. TimescaleDB hypertable on `timestamp`, monthly chunks, 365-day floor. For M0 a plain
table is acceptable if hypertable setup is deferred (conflict C4), but the **shared audit-emit
helper and the emitting call sites are in scope**.

---

## 4. Contexts & Ecto schemas

- `Codefresh.Organizations` (extend): `create_organization/2` (creates org + owner membership in one
  `Ecto.Multi`), `get_organization/1`, `list_organizations_for_user/1`, `create_membership/3`,
  `list_memberships/1`, `get_membership/2`.
- `Codefresh.ApiTokens` (**new**, `lib/codefresh/api_tokens.ex`):
  ```elixir
  @spec issue_token(org :: Organization.t(), attrs :: map(), actor :: User.t() | nil) ::
          {:ok, %{token: ApiToken.t(), raw: binary()}} | {:error, Changeset.t()}
  def issue_token(org, attrs, actor)          # mints raw, hashes, returns raw ONCE
  def list_tokens(org_id)                      # never returns raw or token_hash
  def get_token(org_id, id)
  def revoke_token(token)                      # sets revoked_at; invalidates cache
  def rotate_token(token, actor)               # revoke old + issue new (same name/role/expiry) atomically
  def authenticate(raw_token)                  # {:ok, %{org_id, role, token}} | {:error, :invalid | :revoked | :expired}
  ```
  Raw token: `:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)`; `key_prefix` =
  first 8 chars; hash via Bcrypt. `authenticate/1` narrows candidates by indexed `key_prefix`, then
  `Bcrypt.verify_pass/2` (timing-attack-resistant), rejects when `revoked_at` set or
  `expires_at < now()`, updates `last_used_at`.
- `Codefresh.Audit` (**new**): `emit(action, subject_type, subject, conn_meta, opts)` — the shared
  helper every controller mutation calls (DoD §10).
- Schemas: `@primary_key {:id, :binary_id, autogenerate: true}`, `timestamps(type: :utc_datetime)`,
  changesets with `validate_required` + `unique_constraint`.

---

## 5. API surface (OpenAPI-spex documented — all under `/api/v1`)

Session/JWT-authenticated browser endpoints (existing `:authenticated` pipeline):

| Method | Path | Story | Behavior |
|---|---|---|---|
| POST | `/api/v1/organizations` | US-039 | Create org `{name, slug?}`; caller → owner membership; sets active org. 201 |
| GET | `/api/v1/organizations` | US-039 | Orgs the caller is a member of |
| GET | `/api/v1/organizations/:org_id` | US-039 | Org detail; 403 if not a member |
| POST | `/api/v1/organizations/:org_id/memberships` | US-040 | Add member `{email, role}` |
| GET | `/api/v1/organizations/:org_id/memberships` | US-040 | Member list with roles |
| GET | `/api/v1/organizations/:org_id/api_tokens` | US-096 | Token list (no raw, no hash) |
| POST | `/api/v1/organizations/:org_id/api_tokens` | US-096 | Issue `{name, role, expires_at?}` → raw ONCE. 201 |
| POST | `/api/v1/organizations/:org_id/api_tokens/:id/revoke` | US-097 | Set `revoked_at`; 200 |
| POST | `/api/v1/organizations/:org_id/api_tokens/:id/rotate` | US-097 | Revoke old + issue replacement → new raw ONCE. 201 |

**Bearer auth plug** (`ApiTokenAuth`, new): resolves `Authorization: Bearer <token>` via
`ApiTokens.authenticate/1`, assigns `{org_id, role}` to the conn. Result cached in **Redis keyed by
token hash, TTL ≤ 60s** so revocation propagates within the grace period (US-097 AC5). This plug
gates future SDK/CLI routes; M0 needs the plug + one smoke route to prove it.

Response shapes: token create/rotate return `{id, name, role, key_prefix, expires_at, token: "<raw>"}`
— `token` present **only** on create/rotate. List/show omit `token` and `token_hash` entirely.

---

## 6. Authorization rules

- Membership roles ranked `owner > admin > editor > viewer`. Org reads require any membership.
- **US-039:** any authenticated user may create an org (becomes owner).
- **US-040:** `owner` or `admin` may add members. **Only `owner` may grant the `:owner` role** (admin
  granting owner → 403). Role must be one of `:owner|:admin|:editor|:viewer` (membership set — **not**
  `:ci`, which is token-only; conflict C2).
- **US-096/097:** `owner` or `admin` may list/issue/revoke/rotate tokens. Token `role` may be any of
  `:owner|:admin|:editor|:viewer|:ci`; the **create form exposes `editor|viewer|ci`** (screen 37 /
  US-096) while the column/API accept the full set (conflict C1).
- Cross-org access is 403 (never 404-leak beyond existence): a member of org A hitting org B's
  memberships/tokens gets 403.

---

## 7. UI surface (frontend, `data-cy` per `docs/cypress-attributes.md`)

Both surfaces live under **Organization Settings** (screen 24):

- **General section** — org name + slug (US-039 create form: `name` required, `slug` auto-derived
  from name, editable, uniqueness-checked). Empty-org state renders a "create your first script" CTA.
- **Members section** — member list (email, role) + invite form (email input + role picker
  `owner|admin|editor|viewer`) (US-040). Owner-only roles disabled for admins.
- **API Tokens section** (screen 37) — token list (name, role, created_at, expires_at, last_used_at;
  never raw), create form (name, role picker `editor|viewer|ci`, expiry date defaulting **90 days**),
  one-time **token reveal** with copy affordance, per-token **Revoke** and **Rotate** actions.
- **Auth-UI fix (Stage 0):** new `<AuthCard>` wrapper (`components/auth-card.tsx`) using
  `@the-robot-lives/styleguide` tokens; login/signup forms wrapped; signup gains an `invite_token`
  input; `auth.tsx` forwards `invite_token` in the register request.

All interactive elements carry `data-cy` / `data-cy-id` / `data-cy-for` / `data-cy-value` /
`data-cy-scope`; TypeScript strict.

---

## 8. Stage-0 platform foundations (non-story — required for exit gates)

Per `IMPLEMENTATION-PLAN.md` §6. In scope for M0, verified by CI:

1. Add `mix.exs` deps: `oban ~>2`, `opentelemetry* ~>1`, `open_api_spex ~>3`, `stream_data`,
   `excoveralls`, `credo`, `dialyxir`.
2. Wire **Oban** into `application.ex` supervisor + `config.exs` (scheduler infra — US-069 depends on it later).
3. Wire **outbound OTel** exporter; instrument Phoenix + Ecto spans (`opentelemetry_phoenix`/`_ecto`).
4. Configure **open_api_spex** base `ApiSpec` module; hook into router; emit schema for CI diff.
5. **Execute the staged migrations** against dev + CI DBs (verify pgvector; reinit shared DB volume).
6. Run dev seeds (captures printed invite tokens).
7. **Cypress scaffold**: install; `cyAttrs` helper; `cypress/config.ts`, `support/commands.ts`
   (`getByCy`, `getByCyId`, `getByCyFor`, `withinScope`, `pair`), `support/e2e.ts`; `smoke.cy.ts` with
   four scenarios (login happy, login invalid, signup-with-invite happy, signup-without-invite rejected).
8. **CI**: `.github/workflows/backend.yml` (format, `compile --warnings-as-errors`, coveralls, credo,
   dialyzer) + `frontend.yml` (lint, `tsc --noEmit`, cypress smoke) + story-status diff check +
   `scripts/regen-user-stories-index.sh`.
9. **Audit ingest**: `audit_events` table + shared `Codefresh.Audit.emit/*` helper; every controller
   mutation in this PRD emits a row (§10 DoD).

---

## 9. Stage-0.5 contract freeze (Lane B — no stories, blocks all downstream milestones)

Freeze, version, and merge under `docs/arch/`, each with a schema artifact validated in CI:

1. **OpenAPI spec** — the API surface all frontends, CLI, and SDKs consume (emitted by open_api_spex;
   this PRD's endpoints are its M0 content). Frozen file diffed per PR: additions/deprecations only,
   no breaking changes.
2. **YAML script schema** — import/export format (feeds US-007/008, CLI runs).
3. **Rubric DSL JSON-schema** — scoring configuration format.
4. **OTLP receiver contract** — inbound span shape for M6 ingestion and the M6 SDK OTel bridge.

Exit requires the four documents versioned + merged and the cross-lane CI run (§15 integration task).

---

## 10. Functional requirements & acceptance criteria (TDD-ready, Given/When/Then)

### FR-039 — Create an organization (US-039)
- **AC1** Given an authenticated user, When they POST `/organizations {name, slug}` with a unique
  slug, Then an `organizations` row and a `memberships` row (`role = :owner`, that user) are created
  in one transaction and 201 returns the org.
- **AC2** Given no slug supplied, When creating, Then `slug` is auto-derived from `name` (URL-safe),
  editable pre-submit.
- **AC3** Given a slug that collides with an existing org, When creating, Then 422 with a clear
  "slug already taken" error and no rows written.
- **AC4** Given a successful create, Then the caller's **active org** switches to the new org (session/JWT claim).
- **AC5** Given a newly created empty org, When its dashboard renders, Then the "create your first
  script" CTA shows.
- **AC6** An `audit_events` row `action=organization_created, subject_type=organization` is emitted.

### FR-040 — Invite/add a member (US-040)
- **AC1** Given an owner/admin, When they POST `/organizations/:id/memberships {email, role}` and the
  email matches an existing user, Then a `memberships` row is created immediately and 201 returns it.
- **AC2** Given the email matches **no** user, When adding, Then a pending **org-scoped, email-bound
  `invite_tokens`** row (`organization_id` set, `email` set, `role`) is recorded; on that email's
  later invite-redeeming signup, membership is auto-created (existing `register_user_with_invite/2`).
- **AC3** Given an admin (not owner) attempts `role = :owner`, Then 403 — only owners grant owner.
- **AC4** Given a `(organization_id, user_id)` that already exists, When adding, Then 422 "already a
  member"; and a duplicate pending email invite is blocked by the partial-unique index (422).
- **AC5** Role must be `:owner|:admin|:editor|:viewer`; any other value → 422.
- **AC6** An `audit_events` row `action=membership_created` is emitted.

### FR-096 — Issue an API token (US-096)
- **AC1** Given an owner/admin, When they POST `/organizations/:id/api_tokens {name, role, expires_at?}`,
  Then an `api_tokens` row is created with `token_hash` (bcrypt), `key_prefix`, and the **raw token is
  returned exactly once** in the 201 body; subsequent reads never expose it.
- **AC2** Given `expires_at` omitted, Then it defaults to `now() + 90 days`; a "never expires" choice
  maps to `NULL` (nullable column = non-expiring).
- **AC3** `role` accepts `editor|viewer|ci` from the form (column accepts the full 5-value set).
- **AC4** Given a duplicate `(organization_id, name)`, Then 422 "name already used".
- **AC5** Given a request bearing `Authorization: Bearer <token>` for a valid, non-revoked,
  non-expired token, Then the `ApiTokenAuth` plug resolves org + role and `last_used_at` updates.
- **AC6** Token list shows name, role, created_at, expires_at, last_used_at — never the raw value or hash.
- **AC7** An `audit_events` row `action=token_created` is emitted.

### FR-097 — Revoke / rotate an API token (US-097)
- **AC1** Given a token, When owner/admin POSTs `.../:id/revoke`, Then `revoked_at` is set and every
  subsequent bearer request with that token gets **401**.
- **AC2** Given a revoked token cached in Redis, Then requests get 401 **within 60s** (cache TTL bound).
- **AC3** Given a token, When owner/admin POSTs `.../:id/rotate`, Then a new token with identical
  `name`/`role`/`expires_at` is created, the old one revoked, and the **new raw token returned once**;
  both actions succeed or neither (atomic).
- **AC4** Revoked tokens remain listed for 90 days (audit) then archive.
- **AC5** `audit_events` rows `action=token_revoked` / `token_rotated` are emitted.

---

## 11. Non-functional requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | New-code test coverage (ExUnit + DataCase + ConnCase) | ≥ 80% line (excoveralls gate) |
| NFR-2 | Token bearer-auth resolution | timing-attack-resistant (prefix-narrow + bcrypt verify) |
| NFR-3 | Revocation propagation | ≤ 60s (Redis token-hash cache TTL) |
| NFR-4 | Raw token exposure | returned once (create/rotate); never stored plaintext, never re-read |
| NFR-5 | Migrations | apply + roll back cleanly on a disposable CI DB (up-down-up) |
| NFR-6 | Every controller mutation | emits `audit_events` row + OTel span (DoD §10) |
| NFR-7 | OpenAPI schema diff per PR | additions/deprecations only; no breaking changes |
| NFR-8 | Controller tests | cover happy + 401 + 422 + 403 cross-org paths (DoD §4) |

---

## 12. Error handling

| Condition | HTTP | Body |
|---|---|---|
| Slug collision (US-039) | 422 | `{error: "slug_taken"}` |
| Duplicate member (US-040) | 422 | `{error: "already_member"}` |
| Duplicate pending invite (US-040) | 422 | `{error: "invite_pending"}` |
| Admin grants owner role (US-040) | 403 | `{error: "owner_role_forbidden"}` |
| Invalid role value | 422 | `{error: "invalid_role"}` |
| Duplicate token name (US-096) | 422 | `{error: "token_name_taken"}` |
| Bearer token revoked/expired/invalid (US-097) | 401 | `{error: "unauthorized"}` |
| Cross-org access | 403 | `{error: "forbidden"}` |
| Unauthenticated | 401 | `{error: "unauthorized"}` |

---

## 13. Out of scope

Personal-org auto-provision + first-user UX (Wave 2); email accept-link invites; role change / member
removal UI (Wave 2); token per-resource ACLs, OAuth grant, introspection endpoint (Wave 3); SSO/SCIM
(Wave 3); org billing; org deletion; the CLI itself (M7 — only its token contract is frozen here).

---

## 14. Dependencies & gates

- **Entry:** none (origin milestone). Auth + invite tokens already implemented.
- **Blocks:** US-040 depends on US-039; US-097 depends on US-096; US-087 (CLI login, M7) is
  forward-loaded onto US-096/097. Everything downstream is gated on Lane B contract freeze.
- **Exit gates (roadmap):** migrations executed dev+CI; `mix test` green in CI; Oban up; ≥1 Cypress
  smoke passing; login→create-org→invite→issue-token works E2E; four contracts frozen/versioned/merged;
  the cross-lane CI run exercises the flow against the frozen OpenAPI spec and validates the four docs.

---

## 15. Conflicts found (report — not silently resolved)

- **C1 — token role enum vs create form.** `data-model.md` §14.1 `api_tokens.role` = 5 values
  (`:owner|:admin|:editor|:viewer|:ci`); US-096 AC + screen 37 expose only `editor|viewer|ci` in the
  create form. PRD treats column/API as the full 5 and the **form as a 3-value subset**. Confirm intent.
- **C2 — membership roles vs invite_tokens comment.** §4 `memberships.role` lists **4** roles
  (`:owner|:admin|:editor|:viewer`); §14.16 says `invite_tokens.role` "matching `Membership.roles()`"
  then lists **5** (adds `:ci`). These disagree. PRD assumes memberships = 4 (no `:ci` membership),
  tokens = 5. `Membership.roles()` should not include `:ci`. Needs a data-model fix.
- **C3 — token expiry default vs nullable column.** US-096 says "default 90 days"; §14.1 says
  `expires_at` nullable = non-expiring. PRD resolves: form default = `now()+90d`, explicit "never" =
  `NULL`. Confirm a "never expires" option is even offered (US-096 implies a default, not never).
- **C4 — audit_events is tagged Wave 3.** §14.8 tags `audit_events` Wave 3, but Stage 0 checklist
  ("audit ingest") and DoD §10 ("every new controller mutation emits an `audit_events` row") require
  it in M0. PRD **forward-loads** the table + emit helper into M0; the TimescaleDB hypertable
  conversion may lag (plain table acceptable for M0). Confirm this forward-load is intended.
- **C5 — story wave labels vs milestone.** US-096/097 frontmatter is `wave: 2`, but the roadmap and
  impl-plan §15 place them in Stage 0 (forward-loaded). Non-blocking; note for frontmatter reconciliation.
