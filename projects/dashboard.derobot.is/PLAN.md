# dashboard.derobot.is — Central Invite & Signup Console

**Status:** proposed, awaiting go/no-go
**Session:** d23075fb-b3ba-48b5-9a29-98fec138f357
**Date:** 2026-07-27

Centralized admin console to mint/revoke invite tokens, grant users invite
allowances, and view signups across the whole portfolio.

---

## 1. What already exists (recon findings)

### Invite tokens — ~20 near-identical copies, zero shared state

Every `start-app`-derived backend already ships the invite scaffold:

- `db/changelog/010-invite-tokens.yaml` → `invite_tokens`
  (`id, organization_id, created_by_user_id, token_hash, key_prefix, email,
  max_uses, uses, expires_at, revoked, status, accepted_by, accepted_at`)
- `db/changelog/022-enhance-invitations.yaml` → adds `status/accepted_by/accepted_at`
- `lib/<app>/schema/organizations/invite_token.ex`
- registration-with-invite path in each `auth_controller.ex`

Present in: aifighter, codefre.sh, derobot.is, designing.derobot.is, foryou,
game-workshop/robotwars, gotta.cc, iotgo, jailbreakingsite, noizu.com, NPL,
therobotdrafts/vnext, therobotknows, therobotlearns, therobotlives,
therobotmakes, therobotremembers, therobotsdayjob, timely, tobarnalp, tobornalp.

**Scaffold-version split:** newer apps (TRD vnext, therobotlearns, timely,
tobornalp) additionally have `invite_token_redemptions`
(`invite_token_id, user_id, redeemed_at, remote_ip, user_agent`). Older ones only
have the scalar `accepted_by`/`accepted_at`.

These are **forks, not a shared dependency**. Fixing the scaffold fixes future
apps only; existing apps each need their own patch.

### Two kinds of invite (important distinction)

| kind | meaning | belongs |
|---|---|---|
| **Platform invite** | "you may create an account on this site at all" | **central** — this project |
| **Org invite** | existing user invites a colleague into *their org* inside one app | **local** — leave the scaffold alone |

The existing `invite_tokens` table is org-scoped (`organization_id`) and serves
the second case. We are building the first case. **We do not rip out the
scaffold.**

### Signups — foryou is already the central collector

Two real implementations exist (plus many decorative frontend-only forms):

1. **foryou Lists domain** — the mature one. `lists` (project-scoped, with
   globally-unique `public_slug`, `kind: newsletter|waitlist|inquiry|contact|mixed`),
   `list_attributes` (typed no-migration field model, one `is_identity` email
   field enforced by partial unique index), `signups`. Public submission
   controller, `/api/v1/management` CRUD, `/api/v1/admin` console with aggregate
   + CSV export. noizu.com already posts contact inquiries here.
2. **therobotlearns** — `TheRobotLearns.Waitlist` + `waitlist_signups`
   (`email, invite_token, focus, status[waitlist|invited], source`), public
   `POST /api/v1/waitlist`, admin `GET /api/v1/admin/waitlist`.

**Decision: do not build a third.** The dashboard *reads* foryou as the canonical
signup store, plus TRL's waitlist table. Remaining decorative forms get pointed
at foryou lists over time (out of scope for v1).

### Auth / identity

- **Authentik** is the IdP — `auth.noizu.com` **and `auth.derobot.is`** already
  exist (`terraform/kubernetes/infra-services/authentik.tf`, raw TF not Helm).
- Per-app OIDC creds live in `.infisical-secrets.yaml` under the
  `platform-authentik` block (path `/platform/authentik`), pattern
  `<APP>_OIDC_CLIENT_ID` / `<APP>_OIDC_CLIENT_SECRET`.
- **No unified admin concept.** NPL uses a `role` enum
  (`[:user,:moderator,:admin,:owner,:service,:other]`, admin = `role in [:admin,:owner]`);
  every other app uses a **boolean `users.admin`** checked by `Plugs.RequireAdmin`.
  Org-scoped access uses `Plugs.RequireRole` (viewer/editor/admin/owner).
- **No shared users table.** Every app has its own `users`, its own Repo, its own
  orgs. There is no cross-app identity store — this is the core reason a central
  service is needed at all.
- **M2M precedent:** NPL's MCP API keys (bcrypt-hashed, admin-mintable,
  `POST /api/mcp/token` exchanges raw key → short-lived JWT). Good pattern to
  copy for site→dashboard auth. NPL-specific today.

### Deploy shape — nearly free

- **DNS:** `terraform/cloudflare/zones/derobot.is/main.tf` has a wildcard
  `CNAME * → derobot.is`. **`dashboard.derobot.is` needs no new record.**
- **TLS:** shared `derobotis-tls` secret (Infisical `/apps/tls/derobotis`),
  already used by designing.derobot.is. Reference by name, no cert work.
- **Postgres:** shared `app-timescaledb.apps:5432`, one DB per app via
  `provision-db`.
- **Helm:** copy `components/start-app/helm/start-app/` →
  `projects/dashboard.derobot.is/helm/<name>/`. (`kubernetes/helm/apps/` is
  upstream-only; every recent app uses the in-project pattern.)
- **`.infra-config.yaml`:** 5 stanzas — tier-3 chart list, namespace map
  (`<name>: apps`), `chart_path_overrides`, `projects[]` entry with
  backend+frontend services, `liquibase_targets` DB block. Templates: `ddi`
  (`:1224-1249`, `:409-434`), `therobotlearns` (`:1075-1111`).

---

## 2. Blockers & risks

### 🔴 BLOCKER — Redis: zero free DB indices on `app-valkey`

All 16 claimed: `0` timely, `1` aifighter, `2` codefresh, `3` derobotis,
`4` gotta-cc, `5` iotgo, `6` jailbreaking, `7` start-app (reserved), `8` ddi,
`9` therobotknows, `10` therobotlives, `11` therobotdrafts, `12` therobotplans,
`13` noizu-site, `14` therobotlearns, `15` foryou.

**Recommendation: provision a second Valkey instance** (`app-valkey-2`) rather
than squatting an index or contorting the app to avoid Redis. It's a one-time
structural fix that unblocks this app *and the next fifteen*. Doing anything else
here just re-pays this cost on the next project.

### 🟠 In-flight OIDC security work collides with Phase 5

The working tree has **uncommitted** `sso_controller.ex` + `router.ex` changes
across 16 projects (state/nonce validation — see memory
`oidc-state-nonce-missing-repo-wide`: 23 backends, 6 live). Phase 5 touches
`auth_controller.ex` in the same apps. **That work should land before the
client rollout starts** or the two will conflict file-by-file.

### 🟠 Central service becomes a dependency of every signup path

If the dashboard is down, nobody can sign up anywhere. Mitigated by the signed-code
design in §3 — sites verify validity *offline* and only call central to record
redemption and check remaining uses.

### 🟡 Other

- Two admin models (role enum vs boolean) — the dashboard's own admin gate is
  independent, but any call *into* per-app admin APIs must handle both.
- 23 forks, no shared dep — rollout is 23 small patches, not one change.
- Email deliverability for invite sends (SendGrid via port 2525, mandatory TLS).

---

## 3. Architecture

```
                    dashboard.derobot.is
        ┌──────────────────────────────────────────┐
        │  Phoenix backend + Next frontend         │
        │  ┌────────────────────────────────────┐  │
        │  │ platform_invites   invite_grants   │  │
        │  │ invite_redemptions grant_ledger    │  │
        │  │ sites              audit_log       │  │
        │  └────────────────────────────────────┘  │
        └───▲──────────────▲──────────────▲────────┘
            │              │              │
   admin UI │       M2M API│        reads │ (no writes)
   (Authentik OIDC)        │              │
                    ┌──────┴──────┐  ┌────┴─────────────┐
                    │ 23 sites    │  │ foryou Lists     │
                    │ validate/   │  │ TRL waitlist     │
                    │ redeem      │  │ (signup sources) │
                    └─────────────┘  └──────────────────┘
```

### Signed invite codes (resolves the availability risk)

Codes are HMAC-signed payloads, not opaque random strings:

```
TBR-<base32(site_scope|expiry|nonce)>-<hmac_prefix>
```

- Sites verify **signature + expiry offline** using a shared secret (delivered via
  Infisical) → dashboard outage never blocks a signup.
- Sites call central to **record redemption** and check `uses < max_uses` →
  authoritative use-counting, eventually consistent.
- Failure mode is explicit per site: `fail_open` (accept, queue the redemption)
  or `fail_closed` (reject). Default `fail_open` for waitlist-style gates,
  `fail_closed` for paid/limited ones.

### Schema (new, `dashboard` DB)

| table | purpose |
|---|---|
| `sites` | registry: slug, name, base_url, api_key_hash, key_prefix, fail_mode, active |
| `platform_invites` | code_hash, key_prefix, site_id (null = any site), issued_by, issued_to_email, max_uses, uses, expires_at, revoked, status, metadata jsonb |
| `invite_redemptions` | invite_id, site_id, remote_user_ref, email, redeemed_at, remote_ip, user_agent |
| `invite_grants` | subject_email / (site_id, remote_user_ref), allowance, granted_by, reason, expires_at |
| `grant_ledger` | append-only credit/debit rows so allowance math is auditable |
| `audit_log` | every admin action: actor, action, target, before/after jsonb |

Deliberately mirrors the existing scaffold's `token_hash` + `key_prefix`
convention so the two systems read the same way to anyone who knows one.

### M2M API (site → dashboard)

Auth: per-site API key, bcrypt-hashed, `Authorization: Bearer <key>`
(pattern lifted from NPL's `MCPApiKeys.verify_api_key/1`).

```
POST /api/v1/invites/validate   {code, site}            → {valid, remaining, email_constraint}
POST /api/v1/invites/redeem     {code, site, user_ref, email, ip, ua}
                                                        → {ok, invite_id}   (idempotent)
GET  /api/v1/allowance/:user_ref?site=<slug>            → {remaining, expires_at}
POST /api/v1/invites            {site, user_ref, email} → {code}  (debits allowance)
```

### Admin UI (Next, Authentik OIDC)

New Authentik OAuth2 client + `DASHBOARD_OIDC_CLIENT_ID/SECRET` in the
`platform-authentik` block. Screens:

1. **Overview** — invites issued/redeemed/outstanding, signups by site, 30d trend
2. **Invites** — list/filter/mint (single + bulk), revoke, redemption detail
3. **Users & Grants** — search across sites, grant/adjust allowance, ledger view
4. **Signups** — unified feed from foryou Lists + TRL waitlist, CSV export
5. **Waitlist → Invite** — multi-select entries, mint + email, track conversion
6. **Sites** — registry, API key rotation, fail-mode toggle, health
7. **Audit** — full action log

---

## 4. Phases

| # | phase | output | depends on |
|---|---|---|---|
| **0** | **Infra unblock** | 2nd Valkey provisioned; `dashboard` DB; Authentik client + Infisical entries; helm chart; `.infra-config.yaml` stanzas | — |
| **1** | **Central service core** | schema + invites domain + M2M API + API-key auth + admin gate; deployed, mint/revoke/list working | 0 |
| **2** | **Signups aggregation** | read-only unified feed from foryou Lists + TRL waitlist; CSV export | 1 |
| **3** | **Grants** | allowance ledger, grant UI, `/allowance` + user-mint endpoints | 1 |
| **4** | **Waitlist → invite** | promotion flow + SendGrid email + conversion tracking | 2, 3 |
| **5** | **Client rollout ×23** | `Starter.Invites.Client` into `start-app` scaffold first, then per-app patch to `auth_controller.ex` | 1, **OIDC work landed** |

Phases 2 and 3 are independent of each other and can run in parallel.

**Phase 5 note:** the per-app patch is small and near-identical (add client
module, add config, insert validate/redeem call into the registration path,
leave org-invite scaffold untouched). Good candidate for parallel per-app
subagents once the reference patch is proven on one pilot app.

---

## 5. Decisions (settled 2026-07-27)

1. **Redis** — ✅ **provision a second Valkey instance** (`app-valkey-2`) with a
   fresh 0–15 index range. Phase 0 work. Unblocks this app and the next fifteen.
2. **Phase 5 pilot** — ✅ **therobotlearns**. Newest scaffold generation
   (`invite_token_redemptions`), real `waitlist_signups` table, working admin
   surface — exercises every integration point, so the reference patch generalizes.
3. **Sequencing vs. OIDC work** — ✅ **land the state/nonce security work first**,
   then begin Phase 0. Avoids file-by-file conflict in Phase 5 and clears the more
   urgent item on its own merits. See §6.
4. **Default fail mode** — `fail_open` globally to start; flip individual sites to
   `fail_closed` as needed.

---

## 6. Phase −1: land the OIDC state/nonce work (prerequisite)

The working tree has uncommitted CSRF/replay hardening across ~16 files in 10
projects, on top of a `wip` commit. This must be complete, correct, and committed
before Phase 5 — and ideally before Phase 0, since it is a live security issue on
6 production sites.

Known hazard: a partial change to a shared function signature can leave callers
validating nothing while *appearing* fixed ("fixing arity alone makes 14 more
vulnerable"). Any patch must be verified end-to-end per app, not by diff presence.

A correct patch has all of:

1. `state` + `nonce` generated in `oidc_init` with a CSPRNG
2. both stored in a short-lived (~900s) **signed** cookie session
3. `state` compared in **constant time**
4. `state` cleared **before** token exchange (one-time use)
5. `nonce` verified against the `id_token` claim after `OpenIDConnect.verify`
6. every failure path terminates the login — no fall-through to success

Audit in progress; task list to follow.
