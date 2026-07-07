# Standing up a new portfolio stub app (Elixir + Next.js) from `start-app`

A repeatable runbook for scaffolding a new app from the `components/start-app`
template and wiring it end-to-end: scaffold → secrets → Infisical → DB → DNS →
deploy. Written from the `designing.derobot.is` (slug `ddi`) bring-up.

This repo's deploy pipeline is **manual** — there is no one-shot `deploy-service`
that works (it would need `project.yaml` files that nobody has). The real loop is
`docker-build` → `docker-push` → `helm-upgrade`, each reading `.infra-config.yaml`.

> Conventions below use these placeholders — substitute throughout:
> - `<DOMAIN>`  — full domain, e.g. `designing.derobot.is`
> - `<SLUG>`    — short slug for DB user / redis / npm pkg, e.g. `ddi`
> - `<MODULE>`  — PascalCase Elixir module, e.g. `DesigningDerobot`
> - `<OTP>`     — snake_case OTP app, e.g. `designing_derobot` (derived from MODULE)
> - `<DBNAME>`  — postgres db name, e.g. `designing_derobot_is_dev`

---

## 0. Before you start

```bash
echo $NPL_ORG $NPL_PROJECT      # session registration (see CLAUDE.md FIRST ACTION)
```

You need the repo's `direnv`/`dc` env loaded (`.envrc`) so `dc get`, `infisical-populate-secrets`,
`docker-build`, `docker-push`, `helm-upgrade` resolve. Pick:
- **namespace** — portfolio apps go in `apps` (where `app-timescaledb` + site apps live), **not** `apps-ns` (that's the npl-mcp / tobor stack only).
- **redis db index** — `app-valkey` has databases 0–15. Pick a free one:
  ```bash
  grep "6379/" .infisical-secrets.yaml | grep -oE ":6379/[0-9]+" | sort -t/ -k2 -n -u
  ```
- **TLS** — if `<DOMAIN>` is a subdomain of a zone with a wildcard CNAME + wildcard
  cert (e.g. `*.derobot.is`), reuse the existing cert. Otherwise mint a new one
  (see step 4).

---

## 1. Scaffold the app

**IMPORTANT:** run the in-repo copy of the scaffold tool, **not** the
`~/.local/bin` install — the installed copy resolves repo-root to `/` and fails.

```bash
utilities/start-app-scaffold/bin/init-proj-scaffold <DOMAIN> <SLUG> <MODULE> --no-helm
```

This extracts `components/start-app/start-app.tar.gz` into
`projects/<DOMAIN>/app/`, hydrating the Elixir module/OTP names, Dockerfile,
frontend `package.json`, and a `docker-compose.override.yaml` (host port auto-assigned).

You'll see something like:
```
Module:   DesigningDerobot / DesigningDerobotWeb
OTP app:  designing_derobot
DB:       designing_derobot_is_dev (ddi/ddi_dev)
Port:     8080
Frontend: ddi-frontend
```

### Generate the lockfiles (required before `make build`)

The template ships without `mix.lock` or `package-lock.json`, and the frontend
Dockerfile runs `npm ci` (which needs the lock).

```bash
cd projects/<DOMAIN>/app/backend  && mix deps.get                              # → mix.lock
cd projects/<DOMAIN>/app/frontend && npm install --package-lock-only          # → package-lock.json
make init                                                                     # .env files
```

### Fix the Makefile `npm_token` secret

The scaffolded `Makefile` `FRONTEND_BUILD_ARGS` only passes `github_token`, but
the frontend `npm ci` pulls `@noizu:` scoped packages from `npm.noizu.com` and
needs an `npm_token` secret. **This is a template bug — fix it every time.**
Add the line (note: the file uses **tabs**, not spaces):

```makefile
FRONTEND_BUILD_ARGS = \
		--build-arg NEXT_PUBLIC_API_URL=$$(grep NEXT_PUBLIC_API_URL .env 2>/dev/null | cut -d= -f2- || echo "") \
		--secret id=github_token,env=GITHUB_TOKEN \
		--secret id=npm_token,env=NPM_TOKEN
```

Now build all three images to confirm it compiles:
```bash
cd projects/<DOMAIN>/app && make build
```
(`make run` will fail on migrations unless you have a local Postgres — that's
expected; we deploy against the cluster DB, not local.)

### Promote the chart to its canonical location

The scaffold puts the chart at `app/helm/start-app/`. Deploy uses a canonical
copy at `projects/<DOMAIN>/helm/<SLUG>/` (this is what `.infra-config.yaml` and
`helm-upgrade` point at):

```bash
cd projects/<DOMAIN>
mkdir -p helm && cp -R app/helm/start-app helm/<SLUG>
```

Then hydrate `helm/<SLUG>/values.yaml`:
- `domain: <DOMAIN>`
- `backend.image: ops.noizu.com/<DOMAIN>/backend:latest`
- `frontend.image: ops.noizu.com/<DOMAIN>/frontend:latest`
- `migrate.command: ["bin/<OTP>", "eval", "<MODULE>.Release.migrate()"]`
- `database.host: app-postgres.apps.svc.cluster.local`, `database.name: <DBNAME>`
- `redis.host: app-valkey.apps.svc.cluster.local`, `redis.db: <your-free-index>`
- `secrets.name: <slug>-secrets`, `secrets.keys.*: <UPPERSLUG>_*`
- `tls` → reuse wildcard cert or set a new path (step 4)

> **Migrations are Ecto (`.exs`), not Liquibase.** start-app runs schema via the
> chart's migrate hook (`<MODULE>.Release.migrate/0`). Do **not** add a
> `liquibase_targets` entry — there's no Liquibase changelog and `liquibase-shell`
> will error with `changelog-master.yaml does not exist`.

---

## 2. Register in `.infra-config.yaml` (5 edits)

All five live under the repo root `.infra-config.yaml`.

**(a) Tier-3 charts list** (~line 100) — add `<SLUG>` to the Core Applications group:
```yaml
      - <SLUG>
```

**(b) Namespace override** (~line 210) — portfolio apps use `apps`:
```yaml
  <SLUG>: apps
```

**(c) Chart-path registry** (~line 260) — point at the canonical chart:
```yaml
  <SLUG>: projects/<DOMAIN>/helm/<SLUG>
```

**(d) Composite project entry** (in the `projects:` list, near a sibling like
`tobornalp.com`) — backend + frontend with helm stanzas + `helm.charts`:
```yaml
    - domain: <DOMAIN>
      services:
        - name: backend
          dockerfile: app/backend/Dockerfile
          context: app/backend
          registry_path: <DOMAIN>/backend
          auto_detect: false
          helm:
            chart_path: projects/<DOMAIN>/helm/<SLUG>
            values_path: .backend.image
            format: image
        - name: frontend
          dockerfile: app/frontend/Dockerfile
          context: app/frontend
          registry_path: <DOMAIN>/frontend
          build_args:
            NEXT_PUBLIC_API_URL: "https://api.<DOMAIN>"
          auto_detect: false
          helm:
            chart_path: projects/<DOMAIN>/helm/<SLUG>
            values_path: .frontend.image
            format: image
      helm:
        charts:
          - name: <SLUG>
            path: projects/<DOMAIN>/helm/<SLUG>
```

> The `helm:` stanzas are consumed by `docker-push --update-helm` / `deploy-service`.
> Even though we deploy manually, keep them — and keep the path consistent with (c).
> **Path bug trap:** the chart is at `projects/<DOMAIN>/helm/<SLUG>`, **not**
> `projects/<DOMAIN>/app/helm/start-app`. If `helm-upgrade` can't find the chart,
> grep for a stale `app/helm/start-app` reference.

Verify it parses and `docker-build` discovers the targets:
```bash
python3 -c "import yaml; yaml.safe_load(open('.infra-config.yaml'))"  # valid YAML
docker-build <DOMAIN>/backend    # should NOT say "Unknown target"
helm-upgrade --list | grep <SLUG> # should appear in tier 3
```

---

## 3. Secrets: `.envrc.dc` + `.infisical-secrets.yaml`

### 3a. Generate secret values

```bash
openssl rand -hex 32   # db_password
openssl rand -hex 32   # secret_key_base
openssl rand -hex 32   # guardian_secret_key
openssl rand -hex 16   # oidc_client_id
openssl rand -hex 32   # oidc_client_secret
```

### 3b. Pin into `.envrc.dc` (under the `apps:` block)

```yaml
apps:
  ...
  <slug>_db_user: <SLUG>
  <slug>_db_password: "<db_password hex>"
  <slug>_secret_key_base: "<secret_key_base hex>"
  <slug>_guardian_secret_key: "<guardian_secret_key hex>"
  <slug>_oidc_client_id: "<oidc_client_id hex>"
  <slug>_oidc_client_secret: "<oidc_client_secret hex>"
```

(Use `dc get services apps.<slug>_db_password --reveal --raw` to read these back
without leaving them on screen.)

### 3c. Add an Infisical section in `.infisical-secrets.yaml`

Copy the `tobornalp` block (path `/apps/tobornalp`) and adapt. Add it next to a
sibling (e.g. after `therobotplans`). Key bits:

```yaml
  # --- <DOMAIN> ---
  - id: apps-<slug>
    title: "<DOMAIN>"
    path: /apps/<slug>
    vars:
      _<abbr>_db_user:
        dc: services apps.<slug>_db_user
        override: <UPPERSLUG>_DB_USER
        default: <SLUG>
      _<abbr>_db_pass:
        dc: services apps.<slug>_db_password
        override: <UPPERSLUG>_DB_PASSWORD
      _<abbr>_redis_pass:
        dc: auto platform_valkey_password
        override: PLATFORM_VALKEY_PASSWORD
    secrets:
      <UPPERSLUG>_DB_USER:     { ref: _<abbr>_db_user }
      <UPPERSLUG>_DB_PASSWORD: { ref: _<abbr>_db_pass }
      <UPPERSLUG>_REDIS_URL:
        template: "redis://:{{_<abbr>_redis_pass|urlencode}}@app-valkey.apps.svc.cluster.local:6379/<INDEX>"
      <UPPERSLUG>_DATABASE_URL:
        template: "ecto://{{_<abbr>_db_user}}:{{_<abbr>_db_pass|urlencode}}@app-postgres.apps.svc.cluster.local:5432/<DBNAME>"
      <UPPERSLUG>_SECRET_KEY_BASE:    { dc: services apps.<slug>_secret_key_base, override: <UPPERSLUG>_SECRET_KEY_BASE }
      <UPPERSLUG>_GUARDIAN_SECRET_KEY:{ dc: services apps.<slug>_guardian_secret_key, override: <UPPERSLUG>_GUARDIAN_SECRET_KEY }
      <UPPERSLUG>_OIDC_CLIENT_ID:     { dc: services apps.<slug>_oidc_client_id, override: <UPPERSLUG>_OIDC_CLIENT_ID }
      <UPPERSLUG>_OIDC_CLIENT_SECRET: { dc: services apps.<slug>_oidc_client_secret, override: <UPPERSLUG>_OIDC_CLIENT_SECRET }
      GHCR_USER: { dc: secrets ghcr.user, override: GHCR_USER, default: the-robot-lives }
      GHCR_TOKEN: { dc: secrets ghcr.token, override: GHCR_TOKEN }
      NPM_TOKEN: { dc: secrets npm.verdaccio_token, override: NPM_TOKEN }
```

**Add `<slug>` to the `apps:` push-group line** (~line 63) so it ships with the
group:
```yaml
  apps: [..., coming-soon, <slug>]
```

### 3d. Push the new section to Infisical

The section id is `apps-<slug>` (not just `<slug>`):
```bash
infisical-populate-secrets --prod --section=apps-<slug> --dry-run   # sanity check
infisical-populate-secrets --prod --section=apps-<slug>
```

---

## 4. TLS cert

**Option A — subdomain of a zone with a wildcard cert (preferred).**
e.g. `*.derobot.is` cert already lives at Infisical `/apps/tls/derobotis`
(keys `DEROBOTIS_TLS_CRT` / `DEROBOTIS_TLS_KEY`). Point the chart at it:
```yaml
tls:
  enabled: true
  secretName: derobotis-tls          # shared
  infisical:
    secretsPath: "/apps/tls/derobotis"
    crtKey: DEROBOTIS_TLS_CRT
    keyKey: DEROBOTIS_TLS_KEY
```
No new cert, no new Infisical entry.

**Option B — standalone cert.** Mint a cert for the domain, drop it at
`.secrets/tls/<slug>/{cert,key}.pem`, add an `apps-tls-<slug>` block to
`.infisical-secrets.yaml` (copy `apps-tls-tobornalp`), and set the chart's
`tls.secretName` + `secretsPath` + `<UPPERSLUG>_TLS_CRT/KEY` accordingly.

---

## 5. Create the Postgres database + role (live cluster)

The DB module's initdb scripts only run on first boot; for an existing
`app-timescaledb` you create the DB/role directly. Two parts:

**(a) Add an initdb script for first-boot consistency** —
`terraform/kubernetes/apps/init/files/postgres/initdb.d/<slug>/init-db.sh`:
```bash
#!/usr/bin/env bash
# <slug> (<DOMAIN>) — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi
create_db "<DBNAME>" "<UPPERSLUG>_DB_USER" "<UPPERSLUG>_DB_PASSWORD"
```

**(b) Create it live now** via the documented `migrate-platform-to-apps.sh`
pattern (generate SQL from `dc`, pipe into psql on the pod). Add a block to that
script for record-keeping, then run a one-off:
```bash
cat > /tmp/<slug>-sql-gen.sh <<'EOF'
cat <<SQL
CREATE ROLE <SLUG> WITH LOGIN PASSWORD '$(dc get services apps.<slug>_db_password --reveal --raw 2>/dev/null)';
CREATE DATABASE <DBNAME> OWNER <SLUG>;
GRANT ALL PRIVILEGES ON DATABASE <DBNAME> TO <SLUG>;
\c <DBNAME>
GRANT ALL ON SCHEMA public TO <SLUG>;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO <SLUG>;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO <SLUG>;
SQL
EOF
bash /tmp/<slug>-sql-gen.sh > /tmp/<slug>.sql

kubectl port-forward -n apps svc/app-timescaledb 54338:5432 &
PGPASSWORD=$(kubectl get secret app-timescaledb-secrets -n apps -o jsonpath='{.data.postgres-password}' | base64 -d) \
  PGUSER=postgres psql -h 127.0.0.1 -p 54338 -d postgres -f /tmp/<slug>.sql
```
(54338 is just an example local port — pick one free; the infra liquibase
targets use 54330–54338.) Verify with `liquibase-shell`-style connection or a
plain `psql` as the new role.

---

## 6. Terraform: InfisicalSecret CRD (so the app Secret exists in-cluster)

The chart reads runtime secrets from a K8s `Secret` named `<slug>-secrets`
(values.yaml `secrets.name`). That Secret is materialized by an
`InfisicalSecret` CRD syncing Infisical `/apps/<slug>` into it. **Check first**
— it may already exist (the operator or an earlier step may have applied it):
```bash
kubectl get infisicalsecret -n apps | grep <slug>
kubectl get secret <slug>-secrets -n apps
```
If present and `Ready`, skip creation (just back it with TF + import — below).

To create/back it, add `terraform/kubernetes/apps/init/<slug>-site.tf` modeled
on `tobornalp-site.tf`:

```hcl
resource "kubectl_manifest" "infisical_<slug>_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-<slug>-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels    = { "app.kubernetes.io/name" = "<slug>-secrets"
                    "app.kubernetes.io/managed-by" = "terraform" }
    }
    spec = {
      resyncInterval = local.infisical_base.resync_interval
      hostAPI        = local.infisical_base.host_api
      authentication = {
        universalAuth = {
          credentialsRef = {
            secretName      = local.infisical_base.credentials_secret
            secretNamespace = local.infisical_base.credentials_namespace }
          secretsScope = {
            projectSlug = local.infisical_base.project_slug
            envSlug     = local.infisical_base.env_slug
            secretsPath = "/apps/<slug>" } } }
      managedSecretReference = {
        secretName      = "<slug>-secrets"               # must match values.yaml secrets.name
        secretNamespace = kubernetes_namespace_v1.apps.metadata[0].name
        creationPolicy  = "Owner"
        secretType      = "Opaque"
        template        = { includeAllSecrets = true } }
    }
  })
  depends_on = [kubernetes_namespace_v1.apps]
}
```

> A `helm_release` TF resource is optional — tobornalp has one, but most apps are
> deployed via `helm-upgrade` instead. Pick one and be consistent within the app.

Apply (needs MinIO port-forward `127.0.0.1:9000` + AWS creds per CLAUDE.md):
```bash
cd terraform/kubernetes/apps/init && terragrunt apply
```

**If the CRD already exists live** (created out-of-band), import it into TF state
so the apply is a no-op instead of a conflict:
```bash
cd terraform/kubernetes/apps/init
terragrunt import kubectl_manifest.infisical_<slug>_secrets \
  apis/apps/v1/infisicalsecret/infisical-<slug>-secrets
```
(`kubectl_manifest` import id format: `<group>/<version>/<kind>/<name>`; namespaced
kinds include the namespace as shown.)

---

## 7. DNS

Check the zone for a **wildcard CNAME** first:
```bash
grep -A3 'name    = "\*"' terraform/cloudflare/zones/<zone>/main.tf
```
If a wildcard `*` → apex exists (e.g. `*.derobot.is`), **no DNS work needed** —
`<DOMAIN>` already resolves. Otherwise add an A or CNAME record for the subdomain
in `terraform/cloudflare/zones/<zone>/main.tf` (copy a sibling record) and apply.

---

## 8. Build, push, deploy

> Build/push is typically run by the operator. The chart's migrate hook runs
> Ecto migrations on deploy.

```bash
# Build + push both images (tags :latest, :v1.0.edge, :<git>, :<ts>-<git>)
docker-build --push <DOMAIN>/backend
docker-build --push <DOMAIN>/frontend

# Deploy / upgrade the chart (uses chart_path from .infra-config.yaml, ns apps, tier 3)
helm-upgrade --include <SLUG>            # apply
helm-upgrade --include <SLUG> --preview  # diff vs live first (optional)
```

`helm-upgrade` passes `--reset-values` by default, so the chart's `values.yaml`
is authoritative — pin image tags there (`docker-push --release` rewrites them)
rather than using `helm --set`.

---

## 9. Verify reachable

```bash
kubectl get pods -n apps -l app.kubernetes.io/instance=<SLUG>
kubectl get ingress -n apps
dig +short <DOMAIN>
curl -sS -o /dev/null -w "%{http_code}\n" https://<DOMAIN>
```

A start-app stub returns its landing/dashboard at `/` and the Phoenix API at
`/api` (or `https://api.<DOMAIN>` if the chart wires that subdomain).

---

## Cheat-sheet (the whole loop)

```bash
# scaffold
utilities/start-app-scaffold/bin/init-proj-scaffold <DOMAIN> <SLUG> <MODULE> --no-helm
cd projects/<DOMAIN>/app/backend  && mix deps.get
cd projects/<DOMAIN>/app/frontend && npm install --package-lock-only
# fix FRONTEND_BUILD_ARGS npm_token in app/Makefile (template bug)
cd projects/<DOMAIN> && mkdir -p helm && cp -R app/helm/start-app helm/<SLUG>
# hydrate helm/<SLUG>/values.yaml (domain/images/db/redis/secrets/tls)

# wire config (5 edits in .infra-config.yaml) + secrets (.envrc.dc, .infisical-secrets.yaml + apps group)
# push infisical
infisical-populate-secrets --prod --section=apps-<slug>

# DB live + initdb script + TF InfisicalSecret CRD + (DNS if no wildcard)
# build+push+deploy
docker-build --push <DOMAIN>/backend
docker-build --push <DOMAIN>/frontend
helm-upgrade --include <SLUG>
```

---

## Gotchas (from the ddi bring-up)

- **Run the in-repo scaffold**, not `~/.local/bin` — installed copy breaks repo-root.
- **`npm_token` Makefile bug** — template omits it; frontend `npm ci` of `@noizu:` scoped packages fails. Fix every scaffold.
- **Lockfiles missing** — generate `mix.lock` (`mix deps.get`) + `package-lock.json` (`npm install --package-lock-only`) before `make build`.
- **Chart lives at `projects/<DOMAIN>/helm/<SLUG>`**, not `app/helm/start-app`. Promote + copy. If `helm-upgrade` "can't find chart", grep for a stale `app/helm/start-app` path in `.infra-config.yaml`.
- **Namespace is `apps`**, not `apps-ns` (that's the npl-mcp/tobor stack). Secrets CRD + app pods + DB all in `apps`.
- **Ecto, not Liquibase** — do not add a `liquibase_targets` entry; no changelog exists and `liquibase-shell` errors. Migrations run via the chart's migrate hook.
- **Redis index** — pick a free 0–15 on `app-valkey`; check what's taken before choosing.
- **Secret name is `<slug>-secrets`** — the chart reads runtime secrets from `<slug>-secrets` (values.yaml `secrets.name`); make the TF InfisicalSecret CRD `managedSecretReference.secretName` match exactly. (An earlier draft used `apps-<slug>-secrets` — wrong; the live convention is `<slug>-secrets` in namespace `apps`, e.g. `ddi-secrets`, `tobornalp-secrets`, `aifighter-secrets`.)
- **Wildcard TLS** — if the zone has a wildcard cert, reuse it; don't mint a per-subdomain cert.
- **`--reset-values`** — `helm-upgrade` defaults to it, so `values.yaml` wins; pin tags there.
