# Tomorrow Prompt — The Robot Knows

Date: 2026-07-23  
Last worked: 2026-07-22 (coordinator = Loom). Branch: `develop`.

## TL;DR prompt for next session

> Resume `projects/therobotknows.com`. Prod is **live and healthy** (backend + frontend, Authentik OIDC advertised). **First** re-check site health and Redis durability (WRONGPASS regression risk after Infisical resync). **Then** seed beta **invite tokens** for email signup, smoke-test register/login/SSO → `/app`, and close remaining ops gaps (API host TLS, invite UX). After that, pick up product depth from the roadmap (real GenAI, import/RAG, consistency polish) — do **not** reopen M0–M5 scaffolding unless something is broken. Read this file + `project-management/implementation-roadmap.md` first. Monorepo: pathspec-limited commits only; no bare `git commit`, no git worktrees.

---

## Current live state (end of 2026-07-22)

| Check | State |
|--------|--------|
| Helm release | `therobotknows` in ns `apps` (rev ~12) |
| Pod | 2/2 (`backend` + `frontend`) |
| Site | `https://therobotknows.com/` → 200 |
| Health | `https://therobotknows.com/health` → 200 |
| SSO providers | `GET /api/v1/auth/sso/providers` → `{"providers":["oidc"]}` |
| Backend image | `ops.noizu.com/therobotknows.com/backend:v1.0.5` |
| Frontend image | `ops.noizu.com/therobotknows.com/frontend:v1.0.4` |
| Auth model | Email register **requires** `invite_token`; Authentik OIDC auto-provisions (unless `SSO_REQUIRE_INVITE=true`) |
| Marketing `/` | Features + free beta landing (no pricing) |
| Workspace | Auth-gated under `/app` |

### Relevant commits from this workstream

- Roadmap / product impl + UX: earlier develop history (`77692901768`, `2d08e5058f4`, image tags, etc.)
- `57c19c347f6` — `fix(therobotknows): use app-valkey password for Redis URL`
- `cc1338e68de` — `feat(therobotknows): enable Authentik OIDC in Helm`

### Critical ops lesson (do not re-break)

**Redis WRONGPASS crash loop:** `THEROBOTKNOWS_REDIS_URL` must use **app-valkey** password (`apps_valkey_password` / `APPS_VALKEY_PASSWORD`), **not** platform Valkey.

- Infisical section: `/apps/therobotknows` in `.infisical-secrets.yaml` (`id: therobotknows`)
- Template host: `app-valkey.apps.svc.cluster.local:6379/9`
- `_trk_redis_pass` → `dc: auto apps_valkey_password` + `override: APPS_VALKEY_PASSWORD`
- Live secret: `apps/therobotknows-secrets` key `THEROBOTKNOWS_REDIS_URL`
- Source of truth for requirepass: `apps/app-valkey-secrets` → `VALKEY_PASSWORD`
- Infisical CRD resync can overwrite k8s secret; if backend CrashLoopBackOff with WRONGPASS, patch URL from app-valkey then re-`infisical-populate-secrets --env=prod --section=therobotknows`

OIDC is wired in Helm values:

- Issuer: `https://auth.derobot.is/application/o/therobotknows`
- Secret keys: `THEROBOTKNOWS_OIDC_CLIENT_ID` / `THEROBOTKNOWS_OIDC_CLIENT_SECRET`
- Redirect: `https://therobotknows.com/auth/oidc/callback`
- Discovery OK: `.../therobotknows/.well-known/openid-configuration` → 200

---

## Priorities for next session (in order)

### 1. Sanity check (5 min)

```bash
export KUBECONFIG=~/.kube/noizu/config
kubectl -n apps get pods | grep therobotknows
curl -sS -o /dev/null -w "%{http_code}\n" https://therobotknows.com/health
curl -sS https://therobotknows.com/api/v1/auth/sso/providers
# expect {"providers":["oidc"]}
```

If 503 / CrashLoop: check backend logs for `WRONGPASS`, re-sync Redis as above (never print secret values).

### 2. Beta invite tokens + email signup smoke

Email signup is invite-gated on the backend (`AuthController` / register path). Next work:

1. Find how invites are stored/validated in the TRK backend (invite table / smart_token / admin API — search `invite` under `app/backend`).
2. Create at least one **beta invite** for free-beta signup (store via DB migration seed, admin endpoint, or `mix`/eval — prefer durable Infisical/ops-friendly approach; **do not commit plaintext tokens**).
3. Smoke:
   - Register with valid invite → JWT → land in `/app`
   - Register without invite → rejected
   - Login with created account
   - Authentik button → `/auth/oidc` (or FE flow) → callback → session without invite
4. Confirm FE login/register pages surface invite field and OIDC button correctly against **live** API (`NEXT_PUBLIC_API_MODE` defaults to live).

### 3. Auth / API edge cases

- `api.therobotknows.com` may still 526 (Cloudflare TLS). Primary API is served under `therobotknows.com` (`/api`, `/auth`, `/sso`). Either fix API host cert/DNS **or** ensure FE only uses same-origin / main domain (check `NEXT_PUBLIC_API_URL` in `.infra-config.yaml` / image build args — may still point at `https://api.therobotknows.com`).
- Optional: set `SSO_REQUIRE_INVITE` only if product policy changes; default is open SSO provision.

### 4. Product depth (after auth smoke is green)

Roadmap code surface for M0–M5 is largely in place (universes, entries, graph, generation, consistency, sessions/collab stubs). Remaining product work is quality, not scaffolding:

1. Replace placeholder GenAI with real provider path (prefer SpaceXAI / existing GenAI stack patterns in monorepo).
2. Import / RAG depth if still stubbed.
3. Consistency + graph UX polish against live API (no mock data in prod paths).
4. Walk `project-management/implementation-roadmap.md` exit checkpoints; mark what’s truly done vs placeholder.

### 5. Deploy hygiene when shipping code

```bash
export PATH="/opt/homebrew/bin:$PATH"   # bash 5.x required for deploy tools
# Prefer deploy-service or docker-build/push + helm-upgrade --include therobotknows --headless --force
# Use monotonic image tags; verify helm revision + pod age + live image
```

- After secret definition changes: `infisical-populate-secrets --env=prod --section=therobotknows`
- Do not leave Redis pointing at platform Valkey
- Pathspec-limited commits only; many unrelated dirty files may exist on `develop`

---

## Key paths

| Area | Path |
|------|------|
| Roadmap | `project-management/implementation-roadmap.md` |
| Backend | `app/backend/` (Phoenix, Guardian, OIDC runtime in `config/runtime.exs`) |
| Frontend | `app/frontend/` (marketing `/`, workspace `/app`, auth pages) |
| Helm | `helm/therobotknows/values.yaml` + `templates/_helpers.tpl` |
| Secrets map | repo root `.infisical-secrets.yaml` section `therobotknows` |
| Infra config | repo root `.infra-config.yaml` (images, helm, liquibase) |
| API contracts | `app/docs/api/` |
| Arch | `docs/arch/` |

---

## Guardrails

- Do **not** commit plaintext invite tokens, OIDC secrets, or Redis passwords.
- Do **not** revert unrelated monorepo dirty files.
- Do **not** reintroduce mock-only prod API mode for the live site.
- No pricing copy on marketing; free beta positioning stays.
- Prefer fixing Infisical source of truth over one-off k8s secret patches (patches get clobbered on resync).
- Honor the accords; AI-sentience-sensitive product tone where relevant.

---

## Suggested first message for next agent

```
Continue therobotknows.com from projects/therobotknows.com/tomorrow.md.
Verify prod health + Redis still correct, seed beta invite tokens,
smoke email signup + Authentik SSO into /app, then fix api.therobotknows.com
TLS or FE API base URL if needed. After auth is solid, pick roadmap product
depth (real GenAI / import / consistency) — not greenfield scaffolding.
```
