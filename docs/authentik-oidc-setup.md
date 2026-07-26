# Wiring Authentik OIDC into a start-app service

Canonical runbook for putting an Authentik (`auth.derobot.is`) OIDC login in front
of any `start-app`-derived Elixir + Next.js service. Written from the
`therobotknows.com` bring-up (2026-07-26), corrected against `foryou` and
`therobotlearns`.

Supersedes `docs/foryou-authentik-deploy-howto.md`.
Prerequisite: the app already exists and deploys — see
[`docs/new-start-app-setup.md`](new-start-app-setup.md) for scaffold → secrets →
DB → DNS → first deploy.

> Placeholders used throughout — substitute:
> - `<app>` — chart / Infisical slug, lowercase, e.g. `therobotknows`
> - `<APP>` — the same, uppercase, secret-key prefix, e.g. `THEROBOTKNOWS`
> - `<DOMAIN>` — apex host, e.g. `therobotknows.com`
> - `<MODULE>` — Elixir module, e.g. `Therobotknows`

**Never print secret values.** Every recipe below captures into a shell variable
or uses `dc compare`. Do not paste real client ids/secrets into tickets or chats.

---

## Order of operations

The steps below are dependency-ordered. Doing 5 (DB) before 7 (deploy) matters —
the app will boot and 500 on first login otherwise.

1. [Authentik provider + application](#1-authentik-provider--application)
2. [Secrets: `dc` → Infisical → k8s](#2-secrets-dc--infisical--k8s)
3. [Backend requirements](#3-backend-requirements)
4. [Helm chart](#4-helm-chart)
5. [Database (Liquibase, not Ecto)](#5-database-liquibase-not-ecto)
6. [DNS / TLS](#6-dns--tls)
7. [Build & deploy](#7-build--deploy)
8. [Verify](#8-verify)

---

## 1. Authentik provider + application

Authentik is at `https://auth.derobot.is`. Version in cluster is **2025.6.0** —
the API shapes below are version-specific.

### 1a. Get an API token

```bash
AUTHENTIK_HOST=https://auth.derobot.is
AUTHENTIK_TOKEN="$(dc get services design.authentik_api_token --raw 2>/dev/null)"
[ -n "$AUTHENTIK_TOKEN" ] || echo "EMPTY — check the dc path"

# Confirm it actually works (status only, never print the token):
curl -s -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  "$AUTHENTIK_HOST/api/v3/core/applications/?search=<app>"   # expect 200
```

> [!IMPORTANT]
> Use **`services design.authentik_api_token`**. Verified 2026-07-26: this
> resolves a working token (HTTP 200). **`dc get auto authentik_api_token`
> returns empty** — `auto` is a storage *layer*, not a queryable subject, so it
> is not a valid retrieval path regardless of `--reveal`.
>
> Confusingly, `dc config get services design.authentik_api_token` reports
> *"no source entry found"*, and there is no literal `design.authentik_api_token:`
> declaration under the `design:` block. The value is served through dc's
> auto-layer fallback resolution, so **`dc get` works where `dc config get` and
> grep both look empty**. Don't conclude the key is missing from the fact that
> you can't find its declaration.
>
> To locate keys safely, `dc bat --all --flat --filter-key 'authentik'` prints
> `file:line` + path with **no values**. Note that `dc bat`'s merged view is
> dominated by the stale gitignored `.envrc.dc.bak-foryou` (329 keys vs 17 from
> the live `.envrc.dc`), so treat its file attribution with suspicion.

### 1b. The provider must be *confidential*

> [!WARNING]
> **Do not copy the portfolio static-site OIDC pattern.** Those use
> `client_type: public` with PKCE because there is no server to hold a secret.
> A start-app backend performs the code exchange server-side with
> `OIDC_CLIENT_SECRET`. A public provider will hand back tokens the backend
> cannot validate, or reject the exchange outright.

Required provider fields:

| Field | Value | Why |
|---|---|---|
| `client_type` | `confidential` | backend does a server-side code exchange |
| `client_id` | `<APP>_OIDC_CLIENT_ID` from `dc` | must match the k8s secret exactly |
| `client_secret` | `<APP>_OIDC_CLIENT_SECRET` from `dc` | same |
| `issuer_mode` | `per_provider` | issuer becomes `.../application/o/<app>`, which is what the chart's `sso.oidc.issuer` asserts |
| `sub_mode` | `hashed_user_id` | stable opaque `sub` across email changes |
| `redirect_uris` | see below | `/auth/oidc/callback`, **not** `/auth/callback` |

> [!WARNING]
> **The callback path is `/auth/oidc/callback`.** The old foryou doc and several
> half-configured providers use `/auth/callback`, which is a frontend route and
> 404s the authorization code. The backend route the chart's
> `OIDC_REDIRECT_URI` points at is `https://<DOMAIN>/auth/oidc/callback`
> (see `_helpers.tpl`, `start-app.backendEnv`).

Redirect URIs to register — root, the `app.`/`api.` hosts if the chart serves
them, and local dev:

```
https://<DOMAIN>/auth/oidc/callback
https://app.<DOMAIN>/auth/oidc/callback
https://api.<DOMAIN>/auth/oidc/callback
http://localhost:4000/auth/oidc/callback
http://localhost:3000/auth/oidc/callback
```

### 1c. Create / patch via the API

On 2025.6.0 `redirect_uris` is a **list of objects**, not a newline string:

```bash
CLIENT_ID="$(dc get services apps.<app>_oidc_client_id --reveal --raw 2>/dev/null)"
CLIENT_SECRET="$(dc get services apps.<app>_oidc_client_secret --reveal --raw 2>/dev/null)"

read -r -d '' REDIRECTS <<'JSON'
[
  {"matching_mode":"strict","url":"https://<DOMAIN>/auth/oidc/callback"},
  {"matching_mode":"strict","url":"https://app.<DOMAIN>/auth/oidc/callback"},
  {"matching_mode":"strict","url":"https://api.<DOMAIN>/auth/oidc/callback"},
  {"matching_mode":"strict","url":"http://localhost:4000/auth/oidc/callback"},
  {"matching_mode":"strict","url":"http://localhost:3000/auth/oidc/callback"}
]
JSON
```

**Find the provider pk** (do not assume; slugs and pks drift):

```bash
curl -sS -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  "$AUTHENTIK_HOST/api/v3/providers/oauth2/?search=<app>" \
  | jq '.results[] | {pk, name, client_type, client_id, issuer_mode, sub_mode}'
```

**PATCH** (partial update — this is the safe verb):

```bash
curl -sS -X PATCH \
  -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  -H "Content-Type: application/json" \
  "$AUTHENTIK_HOST/api/v3/providers/oauth2/<pk>/" \
  -d "$(jq -n \
        --arg cid "$CLIENT_ID" --arg csec "$CLIENT_SECRET" \
        --argjson redirects "$REDIRECTS" \
        '{client_type:"confidential",
          client_id:$cid,
          client_secret:$csec,
          issuer_mode:"per_provider",
          sub_mode:"hashed_user_id",
          redirect_uris:$redirects}')" \
  | jq '{pk, client_type, issuer_mode, sub_mode}'
```

> [!WARNING]
> **Use `PATCH`, never `PUT`.** `authorization_flow`, `invalidation_flow`,
> `signing_key`, and `property_mappings` are **shared across every app** on this
> Authentik instance. A `PUT` that omits them nulls them out and breaks logins
> for every other service. If you must `PUT`, `GET` the provider first and echo
> those four fields back verbatim.

Then the application object (`slug` is what appears in the issuer URL):

```bash
curl -sS -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  "$AUTHENTIK_HOST/api/v3/core/applications/?search=<app>" \
  | jq '.results[] | {pk, slug, name, provider}'
```

- `name`: human label, e.g. `TheRobotKnows`
- `slug`: `<app>` — must match `sso.oidc.issuer` in values.yaml
- `provider`: the pk from above
- `meta_launch_url`: `https://<DOMAIN>/`

Restrict who may use it by binding `SSODomains`-equivalent policy or a group —
if you leave the application unbound, **any Authentik account can reach it**.
(The app-side fail-closed defense is in [step 3](#3-backend-requirements); do
both.)

### 1d. Verifying — the trap

```bash
curl -fsS "$AUTHENTIK_HOST/application/o/<app>/.well-known/openid-configuration" | jq .issuer
```

> [!WARNING]
> **A 200 here proves almost nothing.** The discovery document is served for any
> *application* whose slug matches. It does not tell you the provider is
> confidential, that its redirect URIs are right, or — the failure we actually
> hit — that its `client_id` matches what the cluster is sending. Always compare
> explicitly:

```bash
# Authentik's view
curl -sS -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  "$AUTHENTIK_HOST/api/v3/providers/oauth2/<pk>/" | jq -r '.client_id' \
  | sha256sum

# The cluster's view — hash, don't print
kubectl get secret <app>-secrets -n apps \
  -o jsonpath='{.data.<APP>_OIDC_CLIENT_ID}' | base64 -d | sha256sum
```

Matching hashes ⇒ same value. Mismatch ⇒ Authentik will answer the authorize
request with `invalid_client` or silently redirect to an error page.

---

## 2. Secrets: `dc` → Infisical → k8s

The same OIDC client material has to appear in **two** Infisical paths:

- `/platform/authentik` — so the Authentik deployment/bootstrap can see it
- `/apps/<app>` — so the app's `InfisicalSecret` CRD materializes `<app>-secrets`

Both must source from the **same `dc` paths**, or the two halves drift:

```yaml
# .infisical-secrets.yaml — platform-authentik section (path /platform/authentik)
      <APP>_OIDC_CLIENT_ID:
        dc: services apps.<app>_oidc_client_id
        override: <APP>_OIDC_CLIENT_ID
      <APP>_OIDC_CLIENT_SECRET:
        dc: services apps.<app>_oidc_client_secret
        override: <APP>_OIDC_CLIENT_SECRET
```

```yaml
# .infisical-secrets.yaml — the app section (path /apps/<app>) — identical dc paths
      <APP>_OIDC_CLIENT_ID:
        dc: services apps.<app>_oidc_client_id
        override: <APP>_OIDC_CLIENT_ID
      <APP>_OIDC_CLIENT_SECRET:
        dc: services apps.<app>_oidc_client_secret
        override: <APP>_OIDC_CLIENT_SECRET
```

### 2a. Groups — both of them

`groups:` at the top of `.infisical-secrets.yaml`. The app needs a **pair-group**
so authentik + app push together, **and** membership in `apps` so the routine
bulk push includes it. Missing either and `infisical-populate-secrets` silently
skips the section.

```yaml
groups:
  <app>-auth: [platform-authentik, <app>]
  apps: [ ..., <app> ]
```

Worked example (therobotknows):

```yaml
  therobotknows-auth: [platform-authentik, therobotknows]
  apps: [docmost, ..., therobotlearns, therobotknows, tobornalp, ...]
```

### 2b. ☠️ Populate will blank live credentials

> [!CAUTION]
> **`infisical-populate-secrets` writes an EMPTY string for any `dc:`-sourced
> key that does not resolve in the current shell.** In a non-interactive /
> headless / agent shell, `dc` cannot prompt, so an unresolvable path yields
> `""` — and populate happily pushes that empty value over the live one.
>
> If your `/apps/<app>` section has *any* key whose `dc:` path is missing or
> whose subject isn't loaded, running populate will **blank the app's DB
> password, secret key base, and Guardian key**, taking the service down until
> you re-pin and re-push. This is not hypothetical; it is how this failure mode
> was discovered.

**Verify every `dc:` path resolves before you run populate:**

```bash
# List every dc path the app's section references, then probe each one.
grep -A40 "path: /apps/<app>" .infisical-secrets.yaml \
  | grep -oE 'dc: [a-z0-9_]+ [a-z0-9_.]+' | sort -u \
  | while read -r _ subj path; do
      v="$(dc get "$subj" "$path" --reveal --raw 2>/dev/null)"
      printf '%-12s %-48s %s\n' "$subj" "$path" \
        "$([ -n "$v" ] && echo OK || echo '*** EMPTY ***')"
    done
```

Only when every line says `OK`:

```bash
infisical-populate-secrets --prod --section=platform-authentik --dry-run
infisical-populate-secrets --prod --section=<app>              --dry-run
infisical-populate-secrets --prod --section=platform-authentik
infisical-populate-secrets --prod --section=<app>
```

Run the two sections **separately**, not as the `<app>-auth` group — the grouped
push has been observed shelling out through `zellij` in headless environments.

> `override:` env vars beat `dc:`. If a value refuses to resolve from `dc`,
> exporting `<APP>_OIDC_CLIENT_ID=…` for the single populate invocation is the
> documented escape hatch (see `docs/secret-management.md`).

### 2c. `dc config set` does not take effect until direnv reloads

> [!WARNING]
> `dc config set <subject> <path> --value …` edits the raw `.envrc.dc` file
> only. The loaded environment is stale until direnv re-evaluates. A `dc get`
> immediately afterwards returns **empty**, which reads exactly like "the write
> failed" — it didn't.

```bash
dc config set services apps.<app>_oidc_client_id --value "$(openssl rand -hex 16)"
direnv exec . true          # <- mandatory before readback
dc get services apps.<app>_oidc_client_id --reveal --raw >/dev/null && echo set
```

### 2d. Value-safe verification

Use `dc compare`. It reports match/mismatch without printing either side:

```bash
dc compare services apps.<app>_oidc_client_id \
  --to kubernetes://apps/<app>-secrets/<APP>_OIDC_CLIENT_ID
dc compare services apps.<app>_oidc_client_secret \
  --to kubernetes://apps/<app>-secrets/<APP>_OIDC_CLIENT_SECRET
dc compare services apps.<app>_oidc_client_id \
  --to "infisical:///apps/<app>/<APP>_OIDC_CLIENT_ID"
```

> [!WARNING]
> **Never use `dc config get` for verification.** It prints a plaintext preview
> of the value *and its neighbours* in the file. This is how Authentik tokens
> ended up in a transcript on 2026-07-22. Use `dc get … --reveal --raw` into a
> variable, or `dc compare`, or `dc bat --all --flat --filter-key <regex>` (which
> prints `line:path` only).

After populate, let the Infisical operator resync (`resyncInterval` is 120s in
the chart) or force it:

```bash
kubectl get infisicalsecret -n apps | grep <app>
kubectl get secret <app>-secrets -n apps \
  -o go-template='{{range $k,$_ := .data}}{{$k}}{{"\n"}}{{end}}' | sort
```

(Keys only — never dump `.data` wholesale.)

---

## 3. Backend requirements

### 3a. `auth/sso_domains.ex` is mandatory

> [!CAUTION]
> **Without an `SSODomains` module the SSO path auto-provisions *any*
> authenticated email as an active user.** Authentik will happily authenticate
> anyone with an account on the instance — including accounts created for
> unrelated services. The domain map is the app-side fail-closed gate.

Reference implementations:
- `projects/therobotknows.com/app/backend/lib/therobotknows/auth/sso_domains.ex`
- `projects/therobotlearns.com/app/backend/lib/the_robot_learns/auth/sso_domains.ex`

Contract:

| Env var | Format | Meaning |
|---|---|---|
| `SSO_DOMAINS` | `domain=provider;domain=provider` | availability map. **Fail-closed** — a domain absent from the map cannot sign in at all. Multiple providers per domain: comma-separated (`example.com=oidc,google`). |
| `SSO_AUTO_APPROVE_DOMAINS` | comma list (`a.com,b.com`) | of those domains, which land as `:active` on first login. `*` auto-approves everything in the map. |
| `SSO_REQUIRE_INVITE` | `"true"` | when set, an unknown email is rejected outright (`{:error, :user_not_provisioned}`) instead of auto-provisioning. |

Everything in `SSO_DOMAINS` but *not* in `SSO_AUTO_APPROVE_DOMAINS` is created in
the app's pending state. Note that state is **per-app**: therobotknows' `users.status`
enum has no `:pending`, so its `SSODomains` maps pending onto `:waitlist`
(`@pending_status`). Check your app's enum before assuming `:pending` exists.

Worked example (therobotknows values.yaml):

```yaml
sso:
  requireInvite: false
  domains: "derobot.is=oidc;noizu.com=oidc;therobotknows.com=oidc;greatnonprofits.org=oidc;communityconnectlabs.com=oidc"
  autoApproveDomains: "derobot.is,noizu.com,therobotknows.com,greatnonprofits.org,communityconnectlabs.com"
```

### 3b. The `Entity.ref/1` unwrapping defect

> [!WARNING]
> Latent in **any** start-app-derived backend whose OIDC path has never actually
> executed. `Auth.Providers.oidc/0` and friends delegate to `Entity.ref/1`, which
> returns `{:ok, {:ref, _, uuid}}`. `Provider.id/1` accepts only a **bare** ref
> tuple. First real SSO login therefore dies with:
>
> ```
> ** (MatchError) no match of right hand side value:
>    {:error, {:unsupported, {:ok, {:ref, <App>.Auth.Providers.Provider, "…-…-…"}}}}
> ```
>
> It never fires in tests because nothing else calls the provider path.

Fix — unwrap defensively (already applied in both therobotknows and
therobotlearns; copy it into any new app):

```elixir
defp provider_ref(provider_type) do
  case @provider_map[provider_type].() do
    {:ok, provider_ref} -> provider_ref
    provider_ref -> provider_ref
  end
end
```

### 3c. Seed the provider row

Nothing seeds `auth_providers`, so the first SSO login otherwise trips
`user_credentials_auth_provider_id_fkey`. Both reference apps upsert it inline:

```elixir
<MODULE>.Repo.insert(
  %<MODULE>.Schema.Auth.Providers.Provider{id: provider_id, title: title,
    description: "#{title} single sign-on"},
  on_conflict: :nothing, conflict_target: :id)
```

---

## 4. Helm chart

Reference chart: `projects/therobotknows.com/helm/therobotknows/`.

### 4a. `_helpers.tpl` must emit the SSO env

`start-app.backendEnv` needs these blocks. Older scaffolds emit `OIDC_*` but
**not** `SSO_DOMAINS` / `SSO_AUTO_APPROVE_DOMAINS` — check yours; without them
the domain gate is empty and (fail-closed) every login is rejected with
`:sso_not_allowed`.

```gotemplate
{{- if .Values.sso.oidc.issuer }}
- name: OIDC_ISSUER
  value: {{ .Values.sso.oidc.issuer | quote }}
- name: OIDC_CLIENT_ID
  valueFrom:
    secretKeyRef: { name: {{ .Values.secrets.name }}, key: {{ .Values.secrets.keys.oidcClientId }} }
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef: { name: {{ .Values.secrets.name }}, key: {{ .Values.secrets.keys.oidcClientSecret }} }
- name: OIDC_REDIRECT_URI
  value: "https://{{ .Values.domain }}/auth/oidc/callback"
{{- end }}
{{- if .Values.sso.domains }}
- name: SSO_DOMAINS
  value: {{ .Values.sso.domains | quote }}
{{- end }}
{{- if .Values.sso.autoApproveDomains }}
- name: SSO_AUTO_APPROVE_DOMAINS
  value: {{ .Values.sso.autoApproveDomains | quote }}
{{- end }}
{{- if .Values.sso.requireInvite }}
- name: SSO_REQUIRE_INVITE
  value: "true"
{{- end }}
```

### 4b. `sso.oidc.issuer`

```yaml
sso:
  oidc:
    issuer: "https://auth.derobot.is/application/o/<app>"
```

The trailing segment is the **application slug**, and it must match
`issuer_mode: per_provider` on the provider. Get either wrong and the backend
rejects the ID token on issuer mismatch after an otherwise successful login —
which presents as a redirect loop, not an error page.

### 4c. Ingress: the `/auth/sso-callback` carve-out and its ordering

The login round-trip is:

```
browser → /auth/oidc  (backend)   → 302 to auth.derobot.is
auth.derobot.is       → /auth/oidc/callback   (BACKEND — code exchange)
backend               → 302 to /auth/sso-callback  (FRONTEND — sets session, lands the user)
```

So `/auth` as a whole belongs to the **backend**, but `/auth/sso-callback` (plus
`/auth/verify`, `/auth/verify-email`) belong to the **frontend**. nginx-ingress
resolves `Exact` before `Prefix`, but keep the carve-outs physically above the
`/auth` prefix rule anyway — the ordering is load-bearing documentation and
survives ingress-controller changes:

```yaml
      - path: /auth/verify        # Exact  → frontend
      - path: /auth/verify-email  # Exact  → frontend
      - path: /auth/sso-callback  # Exact  → frontend
      - path: /api                # Prefix → backend
      - path: /health             # Exact  → backend
      - path: /auth               # Prefix → backend   <- after the carve-outs
      - path: /sso                # Prefix → backend
      - path: /                   # Prefix → frontend
```

If `/auth/sso-callback` falls through to the backend the user completes the
Authentik flow and lands on a backend 404 with a valid session they can't see.

### 4d. Multi-host ingress + TLS

`therobotknows`' chart templates three host classes:

- `domain` and `appDomain` — frontend, with the backend path carve-outs above
- `apiDomain` — routed **entirely** to the backend (`/` → backend port)

```yaml
domain: <DOMAIN>
appDomain: app.<DOMAIN>
apiDomain: api.<DOMAIN>
```

> [!WARNING]
> **Every host must appear in the ingress `tls.hosts` list.** The chart does this
> by concatenating `$siteHosts` and `$apiHosts`, so it's automatic *if* you set
> the values — but a host present in `rules` and absent from `tls` gets served
> the ingress controller's default certificate. See [step 6](#6-dns--tls); this
> is the actual cause of the 526 you will otherwise chase into DNS.

---

## 5. Database (Liquibase, not Ecto)

> [!CAUTION]
> **The chart's `migrate` hook runs `Release.migrate()`, which is Ecto. These
> apps' schemas are Liquibase. The hook therefore creates nothing, succeeds
> silently, and the deploy looks green with an empty database.**
>
> ```yaml
> migrate:
>   command: ["bin/<app>", "eval", "<MODULE>.Release.migrate()"]   # Ecto — no-op here
> ```
>
> You must run `liquibase-shell` explicitly, or opt into the chart's Liquibase
> hook (below). The first symptom of skipping both is the OIDC callback 500ing
> on `relation "users" does not exist`.

### 5-opt. Run the changelogs from the chart (`migrate.liquibase`)

The start-app chart ships an **opt-in** pre-install/pre-upgrade hook Job that
applies `backend/db/changelog` at deploy time. It is the supported way to get
the schema applied as part of the release. Default is `false`, so nothing
changes until you turn it on:

```yaml
migrate:
  liquibase:
    enabled: true
    image: ops.noizu.com/<slug>/db:v1.0.0
```

It runs at `helm.sh/hook-weight: "-10"`, i.e. strictly before the Ecto
`migrate` hook (`-5`), so the changelogs land first and `Release.migrate()`
then applies the oban/smart_token Ecto migrations on top. DB connection env
(`DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD`) is wired automatically
from `database.*` and `secrets.keys.dbUser`/`dbPassword`; the image builds its
own `jdbc:postgresql://` URL, so no `DATABASE_URL` is involved.

> **Caveat:** `backend/db` is **not** currently a declared build target in
> `.infra-config.yaml` — only `backend` and `frontend` are. A derivative
> adopting this flag must add a `db` service entry (pointing at
> `<app>/backend/db/Dockerfile`) so the image is built and pushed, otherwise
> the hook Job will fail to pull. `migrate.liquibase.image` is required when
> the flag is on; `helm template` errors loudly if it is unset.

### 5a. Register a `liquibase_targets` entry

In root `.infra-config.yaml`. Use **therobotlearns' block as the model** — it is
the most complete:

```yaml
liquibase_targets:
  <app>:
    description: "<DOMAIN> app database on app-timescaledb"
    namespace: apps
    service: svc/app-timescaledb
    remote_port: 5432
    local_port: 543NN                 # pick a free one; infra uses 54330-54340
    db_type: postgresql
    db_name: <app>
    schema: public
    secret_name: <app>-secrets
    secret_namespace: apps
    username: <app>                   # or username_key: <APP>_DB_USER
    secret_key: <APP>_DB_PASSWORD
    safety: destructive
    # provision-db: role creds from dc, superuser from the live instance secret
    role_password_dc: "services apps.<app>_db_password"
    admin_secret: app-timescaledb-secrets
    # Valkey/Redis ACL user (provision: `provision-db <app> --redis-only`)
    redis_password_dc: "services apps.<app>_valkey_password"
    redis_service: svc/app-valkey
    redis_user: <app>
    redis_admin_secret: app-valkey-secrets
    # superuser-only extensions the changelog needs pre-created (pgvector et al.)
    extensions: [citext, uuid-ossp, vector, cube, pg_trgm, earthdistance]
    changelog_dir: projects/<DOMAIN>/app/backend/db
    changelog_file: changelog/db.changelog-master.yaml
```

`changelog_dir` + `changelog_file` are relative-to-repo-root and relative-to-dir
respectively; the resolved path is
`projects/<DOMAIN>/app/backend/db/changelog/db.changelog-master.yaml`. If
`liquibase-shell` says `changelog-master.yaml does not exist`, that join is wrong.

### 5b. Extensions need a superuser

> [!WARNING]
> `CREATE EXTENSION vector` (and `cube`, `pg_trgm`, `earthdistance`,
> `uuid-ossp`) requires **superuser**. The app's login role cannot run them, so a
> changelog that opens with `CREATE EXTENSION` fails on a fresh DB with
> `permission denied to create extension "vector"` — and Liquibase records the
> failure, not a retryable state.

Pre-create them as the instance superuser via `admin_secret`. `provision-db`
does this for you when `extensions:` and `admin_secret:` are both present:

```bash
provision-db <app>            # role + db + extensions, using app-timescaledb-secrets
provision-db <app> --redis-only
```

Manual equivalent, if you need it:

```bash
kubectl port-forward -n apps svc/app-timescaledb 543NN:5432 &
PGPASSWORD="$(kubectl get secret app-timescaledb-secrets -n apps \
  -o jsonpath='{.data.postgres-password}' | base64 -d)" \
PGUSER=postgres psql -h 127.0.0.1 -p 543NN -d <app> -c \
  'CREATE EXTENSION IF NOT EXISTS vector;
   CREATE EXTENSION IF NOT EXISTS cube;
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   CREATE EXTENSION IF NOT EXISTS earthdistance;
   CREATE EXTENSION IF NOT EXISTS citext;
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
```

### 5c. Run the changelog

```bash
liquibase-shell <app> status
liquibase-shell <app> update
liquibase-shell <app> history
```

> [!WARNING]
> **A killed or timed-out `update` leaves a stale changelog lock.** The next run
> hangs or reports `Could not acquire change log lock. Currently locked by …`.
> This is common when running under an agent/CI timeout. Clear it:
>
> ```bash
> liquibase-shell <app> release-locks
> ```
>
> Only do this once you have confirmed no other `update` is genuinely running.
> Then re-run `status` before `update`.

---

## 6. DNS / TLS

### 6a. 526 on `app.` / `api.` is usually NOT a DNS problem

> [!IMPORTANT]
> **The instinct to go fix DNS is wrong.** Where the zone already has a
> wildcard record reaching the cluster, `app.<DOMAIN>` and `api.<DOMAIN>` resolve
> fine. The Cloudflare **526 (Invalid SSL certificate)** means the request got to
> nginx and nginx served a *mismatched* certificate — because the ingress has no
> `rules` entry for that host, so it falls back to the controller's default cert.
>
> **The fix is the ingress**, not DNS: add the host to `rules` (and therefore to
> `tls.hosts`, which the chart derives) with the wildcard cert
> `tls.secretName`. See [4d](#4d-multi-host-ingress--tls).

Diagnose in this order:

```bash
dig +short app.<DOMAIN>                      # resolving? almost always yes
kubectl get ingress -n apps <app> -o jsonpath='{.spec.rules[*].host}{"\n"}'
kubectl get ingress -n apps <app> -o jsonpath='{.spec.tls[*].hosts}{"\n"}'
echo | openssl s_client -connect app.<DOMAIN>:443 -servername app.<DOMAIN> 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName
```

If the SANs don't cover the host, you have your answer.

### 6b. Explicit A records — cleanliness, not the fix

The `cf-zone` module (`terraform/modules/cf-zone`) has `add_app` / `add_api`
booleans that mint explicit proxied `A` records to the cluster IP, instead of
leaning on the wildcard CNAME. Worth doing — a wildcard pointed at a *different*
apex (as `*.therobotknows.com` is, at `derobot.is`) genuinely does misroute — but
it is a separate improvement from the 526.

```hcl
# terraform/cloudflare/zones/<DOMAIN>/terragrunt.hcl
inputs = {
  domain  = "<DOMAIN>"
  add_app = true
  add_api = true
}
```

### 6c. Running Cloudflare terragrunt

> [!CAUTION]
> **Turn the VPN on first.** The Cloudflare API token is IP-allowlisted to the
> static egress. Without the VPN your traffic exits through the CGNAT pool, the
> address rotates, and every API call fails with:
>
> ```
> Authentication error (10000) / code 9109: Unauthorized to access requested resource
> ```
>
> **`/user/tokens/verify` returns 200 even while you are IP-blocked**, so it is
> *not* a valid connectivity check. Verify with a real zone read instead:
>
> ```bash
> curl -sS -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
>   "https://api.cloudflare.com/client/v4/zones?name=<DOMAIN>" | jq '.success, .errors'
> ```

Terragrunt's state backend is MinIO behind Cloudflare Access, which answers
`tofu init` with a 302 HTML login page (`XML syntax error … <hr> closed by
</body>`). Setting `AWS_ENDPOINT_URL_S3` does not help — the explicit
`endpoints` in the backend block wins. Use the wrapper:

```bash
cd terraform
./scripts/tg-minio.sh cloudflare/zones/<DOMAIN> init -reconfigure   # first time / after switching endpoints
./scripts/tg-minio.sh cloudflare/zones/<DOMAIN> plan
./scripts/tg-minio.sh cloudflare/zones/<DOMAIN> apply
```

See `terraform/README.md` for the full explanation of the two override
mechanisms (`TG_MINIO_ENDPOINT` vs `TG_MINIO_BACKEND_CONFIG`).

---

## 7. Build & deploy

> [!WARNING]
> **`deploy-service … --tag vX.Y.Z` pushes the image and then fails its own
> values.yaml bump** with `Invalid version format` — it parses tags as
> `Major.Minor.edge` and chokes on a semver patch number. **The image is already
> in the registry when this happens.** Do not re-run the build; bump
> `values.yaml` by hand.

```bash
deploy-service <DOMAIN>/backend  --prod --tag v1.0.8 --skip-deploy -y   # pushes; bump step errors — expected
deploy-service <DOMAIN>/frontend --prod --tag v1.0.4 --skip-deploy -y
```

Confirm the tags landed, then edit the chart:

```yaml
backend:
  image: ops.noizu.com/<DOMAIN>/backend:v1.0.8
frontend:
  image: ops.noizu.com/<DOMAIN>/frontend:v1.0.4
```

Deploy:

```bash
helm-upgrade --include <app> --preview     # diff live vs proposed
helm-upgrade --include <app>               # passes --reset-values by default
```

`--reset-values` means `values.yaml` is authoritative — pin tags there, never via
`--set`. Use incrementing `vX.Y.Z` tags, not a rolling `v1.0.edge`: helm only
rolls the pods when the image reference actually changes, and the tag is your
provenance record.

---

## 8. Verify

```bash
# Provider list — note the /api/v1 prefix. `/auth/sso/providers` 404s.
curl -fsS https://<DOMAIN>/api/v1/auth/sso/providers | jq .

# Login entry point should 302 to Authentik.
curl -sI https://<DOMAIN>/auth/oidc | sed -n '1p;/^location:/Ip'
#   HTTP/2 302
#   location: https://auth.derobot.is/application/o/authorize/?...client_id=...

# Frontend + app host
curl -sS -o /dev/null -w '%{http_code}\n' https://<DOMAIN>/login
curl -sS -o /dev/null -w '%{http_code}\n' https://app.<DOMAIN>/

# API host root: 404 is CORRECT — the Phoenix router has no "/" route.
curl -sS -o /dev/null -w '%{http_code}\n' https://api.<DOMAIN>/            # 404 = good
curl -fsS https://api.<DOMAIN>/api/v1/auth/sso/providers | jq .            # 200 = good
```

Then drive a real browser login. Backend log signatures for the failures above:

```bash
kubectl logs -n apps -l app.kubernetes.io/instance=<app> -c backend --tail=400 \
  | grep -iE 'sso_not_allowed|user_not_provisioned|invalid_client|issuer|MatchError|auth_provider_id_fkey|does not exist'
```

| Signature | Cause | Fix |
|---|---|---|
| `{:error, :sso_not_allowed}` | email domain absent from `SSO_DOMAINS`, or the var isn't reaching the pod | [3a](#3a-authsso_domainsex-is-mandatory) / [4a](#4a-_helperstpl-must-emit-the-sso-env) |
| `{:error, :user_not_provisioned}` | `SSO_REQUIRE_INVITE=true` and no invite | intended; issue the invite |
| `invalid_client` from Authentik | client_id/secret mismatch, or provider is `public` | [1b](#1b-the-provider-must-be-confidential) / [1d](#1d-verifying--the-trap) |
| issuer mismatch / redirect loop | `sso.oidc.issuer` slug ≠ application slug, or `issuer_mode` ≠ `per_provider` | [4b](#4b-ssooidcissuer) |
| `(MatchError) … {:error, {:unsupported, {:ok, {:ref, …}}}}` | `Entity.ref/1` not unwrapped | [3b](#3b-the-entityref1-unwrapping-defect) |
| `user_credentials_auth_provider_id_fkey` | `auth_providers` row never seeded | [3c](#3c-seed-the-provider-row) |
| `relation "users" does not exist` | Liquibase never ran; Ecto hook was a no-op | [5](#5-database-liquibase-not-ecto) |
| 526 on `app.`/`api.` | ingress has no rule/TLS entry for the host | [6a](#6a-526-on-app--api-is-usually-not-a-dns-problem) |

---

## Checklist

```
[ ] Authentik provider: client_type=confidential, issuer_mode=per_provider,
    sub_mode=hashed_user_id, redirect_uris include /auth/oidc/callback
[ ] PATCH (not PUT) — authorization_flow/invalidation_flow/signing_key/
    property_mappings preserved
[ ] provider client_id hash == k8s secret client_id hash
[ ] .infisical-secrets.yaml: <APP>_OIDC_CLIENT_ID/_SECRET in BOTH
    /platform/authentik and /apps/<app>, same dc paths
[ ] groups: <app>-auth AND apps
[ ] every dc: path in the app section resolves non-empty  <-- before populate
[ ] infisical-populate-secrets --dry-run, then per-section (not the group)
[ ] dc compare vs kubernetes:// and infisical:// — both match
[ ] backend has auth/sso_domains.ex; Entity.ref/1 unwrapped; provider row upserted
[ ] _helpers.tpl emits SSO_DOMAINS + SSO_AUTO_APPROVE_DOMAINS
[ ] values.yaml: sso.oidc.issuer, sso.domains, sso.autoApproveDomains
[ ] ingress: /auth/sso-callback Exact carve-out above /auth Prefix
[ ] ingress: every host in rules AND tls.hosts
[ ] liquibase_targets entry with admin_secret + extensions
[ ] provision-db <app>; liquibase-shell <app> update  (Ecto hook is a no-op)
[ ] cf zone add_app/add_api (VPN on; tg-minio.sh)
[ ] deploy-service push (expect the values-bump error), hand-bump values.yaml,
    helm-upgrade --include <app>
[ ] /api/v1/auth/sso/providers 200; /auth/oidc 302s to auth.derobot.is
[ ] real browser login end to end
```

---

## See also

- [`docs/new-start-app-setup.md`](new-start-app-setup.md) — scaffolding a new start-app service
- [`docs/secret-management.md`](secret-management.md) — `dc` / Infisical reference
- [`terraform/README.md`](../terraform/README.md) — MinIO state backend behind Cloudflare Access
- `projects/therobotknows.com/helm/therobotknows/` — reference chart
- `projects/therobotlearns.com/app/backend/lib/the_robot_learns/auth/sso.ex` — reference backend
