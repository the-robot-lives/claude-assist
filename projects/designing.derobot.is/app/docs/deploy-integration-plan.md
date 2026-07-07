# Deploy Integration Plan — designing.derobot.is (ddi)

**Status:** Planning (not executed) — 2026-07-08
**Slug:** `ddi`
**Registry paths:** `designing.derobot.is/backend`, `designing.derobot.is/frontend`
**Chart:** `start-app` (shared scaffold chart, release name `ddi`, namespace `apps-ns`, tier 3)

---

## 1. Summary of findings

`deploy-service` is the *intended* one-shot utility (build → push → chart-bump → helm upgrade) but it depends on a **`project.yaml`** file that does not exist for *any* project in this repo — not just ddi. The scaffold (`init-proj-scaffold`) does not generate one, and no sibling (aifighter, tobornalp, gotta.cc, etc.) ships one. The actual deploy workflow today is the **manual 3-step path**: `docker-build --push` → `docker-push` (retags + version-bumps + rewrites values.yaml) → `helm-upgrade --include ddi`.

There is also a **critical path bug**: `.infra-config.yaml` declares `chart_path: projects/designing.derobot.is/helm/start-app` (and the `chart_path_overrides` entry on line 264) but the chart physically lives at `projects/designing.derobot.is/app/helm/start-app/` (note the `app/` segment). helm-upgrade will fail to find the chart until this is fixed.

---

## 2. What is already DONE

These pieces are in place and do not need to be redone:

| Item | Location | Notes |
|------|----------|-------|
| Scaffold (start-app) | `projects/designing.derobot.is/app/` | Phoenix backend + Next.js frontend + `helm/start-app/` chart |
| Backend Dockerfile | `app/backend/Dockerfile` | Confirmed present |
| Frontend Dockerfile | `app/frontend/Dockerfile` | Confirmed present |
| Helm chart (values.yaml, templates) | `app/helm/start-app/` | Full start-app chart; `domain: designing.derobot.is`, `tls.secretName: derobotis-tls` (reuses derobot.is wildcard TLS) |
| `.infra-config.yaml` — tier 3 entry | `.infra-config.yaml:103` (`ddi` in tier-3 charts list) | helm-upgrade will pick it up |
| `.infra-config.yaml` — namespace override | `.infra-config.yaml:215` (`ddi: apps-ns`) | |
| `.infra-config.yaml` — chart_path_override | `.infra-config.yaml:264` | **WRONG PATH** — missing `app/` segment (see GAP) |
| `.infra-config.yaml` — composite project | `.infra-config.yaml:903-929` | Declares `designing.derobot.is/backend` + `frontend` with dockerfile/context/registry_path/helm stanzas. docker-build discovers these automatically. |
| `.envrc.dc` secrets | `.envrc.dc:326-331` | `ddi_db_user`, `ddi_db_password`, `ddi_secret_key_base`, `ddi_guardian_secret_key`, `ddi_oidc_client_id`, `ddi_oidc_client_secret` |
| `.infisical-secrets.yaml` — `apps-ddi` section | `.infisical-secrets.yaml:2304-2342` | Full secret set: `DDI_DB_USER/PASSWORD`, `DDI_REDIS_URL`, `DDI_DATABASE_URL`, `DDI_SECRET_KEY_BASE`, `DDI_GUARDIAN_SECRET_KEY`, `DDI_OIDC_CLIENT_ID/SECRET`, GHCR + NPM tokens. Already in the `apps` push-group (line 63). |
| Postgres DB + role | `terraform/kubernetes/apps/init/files/postgres/initdb.d/ddi/init-db.sh` | Creates `designing_derobot_is_dev` DB owned by `ddi` role. (Already provisioned via migrate script at `files/postgres/migrate-platform-to-apps.sh:51-54`.) |
| Liquibase target | `.infra-config.yaml:371-385` | `ddi` target, port-forward `54338`, `ddi-secrets`/`DDI_DB_PASSWORD` |

---

## 3. The GAP — what's missing or broken

### 3a. CRITICAL: chart path mismatch (blocks all deploys)

`.infra-config.yaml` references `projects/designing.derobot.is/helm/start-app` in **three** places, but the chart is physically at `projects/designing.derobot.is/app/helm/start-app/`:

| Line | Field | Current (broken) | Correct |
|------|-------|------------------|---------|
| 264 | `chart_path_overrides.ddi` | `projects/designing.derobot.is/helm/start-app` | `projects/designing.derobot.is/app/helm/start-app` |
| 911 | `project.projects[].services[backend].helm.chart_path` | `projects/designing.derobot.is/helm/start-app` | `projects/designing.derobot.is/app/helm/start-app` |
| 922 | `project.projects[].services[frontend].helm.chart_path` | `projects/designing.derobot.is/helm/start-app` | `projects/designing.derobot.is/app/helm/start-app` |
| 928 | `project.projects[].helm.charts[].path` | `projects/designing.derobot.is/helm/start-app` | `projects/designing.derobot.is/app/helm/start-app` |

**Effect:** `helm-upgrade --include ddi` resolves the chart dir via `_CHART_DIRS["ddi"]` (from `helm-common.sh:54`), points at a non-existent path, and `helm template` / `helm upgrade` fails. This must be fixed before anything else.

### 3b. No Terraform InfisicalSecret CRD for ddi

The K8s `Secret` resource `apps-designing-derobot-secrets` (referenced in `values.yaml` → `secrets.name`) is **not** declared as an `InfisicalSecret` CRD anywhere in `terraform/kubernetes/apps/init/`. Compare `tobornalp-site.tf` (lines 6-47) which creates `kubectl_manifest.infisical_tobornalp_secrets` syncing Infisical path `/apps/tobornalp` → K8s Secret `tobarnalp-secrets`.

For ddi we need a new `designing-derobot-site.tf` (or add to an existing file) that:
1. Creates an `InfisicalSecret` CRD: Infisical path `/apps/ddi` → managed K8s Secret `apps-designing-derobot-secrets` in `apps-ns`.
2. Creates a `helm_release` resource pointing at the chart (optional — see decision point below).

### 3c. ddi missing from `app_db_secrets_map`

`terraform/kubernetes/apps/init/main.tf:39-52` (`app_timescaledb` module) lists `AIFIGHTER`, `TOBORNALP`, etc. in `app_db_secrets_map` so the Postgres init creates per-app credential Secrets. **`DDI` is NOT in this map.** This means the `ddi-secrets` Secret (with `DDI_DB_USER`/`DDI_DB_PASSWORD`) is not auto-provisioned by the DB module. The DB + role *were* created via the initdb script + migrate script, but the credential secret may need manual creation or the map entry added. Verify whether `ddi-secrets` exists in the cluster (`kubectl get secret ddi-secrets -n apps-ns`).

### 3d. No `project.yaml` (affects `deploy-service` only)

`deploy-service` calls `resolve_image_helm()` (lines 121-152) which scans `find "$projects_dir" -maxdepth 5 -name project.yaml`. **Zero `project.yaml` files exist in the entire repo.** This means `deploy-service` will fail for *every* image, not just ddi — it cannot resolve any image → helm mapping. This is a repo-wide gap, not a ddi-specific one.

### 3e. Cloudflare DNS for `designing.derobot.is`

No `designing.derobot.is` DNS record was found in `terraform/cloudflare/`. The chart's ingress template will create the Kubernetes `Ingress`, but without a Cloudflare DNS record (CNAME → the cluster's ingress / tunnel) the domain won't resolve publicly. The `derobot.is` zone exists (managed zone); a subdomain record needs to be added.

### 3f. TLS cert

`values.yaml` sets `tls.secretName: derobotis-tls` and `secretsPath: /apps/tls/derobotis`. This **reuses the existing derobot.is wildcard/origin cert** (already synced via `derobotis-site.tf`). If `designing.derobot.is` is covered by that cert (wildard `*.derobot.is`), this is fine. If the cert is for the bare/apex domain only, a separate TLS cert + Infisical path (`/apps/tls/designing-derobot`) is needed. **Verify the cert covers `*.derobot.is` before deploying.**

---

## 4. The ACTUAL deploy workflow (what the user uses today)

Since `deploy-service` requires `project.yaml` (which nobody has), the real workflow for every start-app sibling is the **manual 3-step path**. Confirmed by reading docker-push (it rewrites values.yaml in place) and helm-upgrade (it reads chart dirs + tiers from infra-config):

```bash
# 1. Build + push backend (also rewrites .backend.image in values.yaml via docker-push --release)
docker-build --push designing.derobot.is/backend

# 2. Build + push frontend (rewrites .frontend.image)
docker-build --push designing.derobot.is/frontend

# 3. Deploy the chart
helm-upgrade --include ddi
```

**Why `--release` matters:** `docker-push` with `--release` rewrites the helm `values.yaml` image tag to the newly-pushed version (see `docker-push:922-964`). Without it, the values.yaml stays on `:latest` and helm-upgrade may not detect a change (helm-upgrade uses MD5 of the chart *dir*, and `:latest` doesn't change between builds). However, the ddi `values.yaml` currently has `backend.image: ...:latest` (not a pinned tag), so the first deploy can proceed as-is; subsequent deploys should use `--release` to pin.

Note: the `helm:` stanzas in `.infra-config.yaml` composite section (lines 908-928) are only consumed by `deploy-service`'s `resolve_image_helm()`. Since we're not using `deploy-service`, those entries are inert for the manual workflow — but they still have the wrong path and should be fixed for correctness.

---

## 5. Decision point: project.yaml or manual workflow?

| Option | Effort | Benefit |
|--------|--------|---------|
| **A. Create `projects/designing.derobot.is/project.yaml`** | Medium — author a new file matching the schema `deploy-service` expects (`.type: composite`, `.projects[].services[].helm`, `.helm.release/namespace/tier/path`). | Enables `deploy-service designing.derobot.is/backend designing.derobot.is/frontend` as a single command. But: no other project has one, so it's a one-off pattern divergence. |
| **B. Use the manual 3-step workflow (recommended)** | Low — just fix the chart path bug + create the TF CRD. | Matches what every other sibling does. Consistent. `deploy-service` is not the user's actual workflow. |

**Recommendation: Option B.** Fix the infra-config path bug, add the Terraform InfisicalSecret CRD, add the Cloudflare DNS record, then use the manual workflow. Creating a `project.yaml` for one project when none exists repo-wide introduces an inconsistency without proportional value. If the user later wants to adopt `deploy-service` broadly, that's a separate repo-wide initiative with its own design (schema, generator in scaffold, migration of all projects).

---

## 6. Step-by-step to "deployed and reachable"

### Step 1 — Fix the chart path bug in `.infra-config.yaml`

Edit `.infra-config.yaml`, change all four occurrences:
```
projects/designing.derobot.is/helm/start-app  →  projects/designing.derobot.is/app/helm/start-app
```
Lines: 264, 911, 922, 928.

### Step 2 — Add Terraform InfisicalSecret CRD for ddi

Create `terraform/kubernetes/apps/init/designing-derobot-site.tf` modeled on `tobornalp-site.tf`:
- `kubectl_manifest.infisical_ddi_secrets`: syncs Infisical `/apps/ddi` → K8s Secret `apps-designing-derobot-secrets` in `apps-ns` (must match `values.yaml` → `secrets.name`).
- Optionally a `helm_release.ddi_site` resource (tobornalp pattern) — OR skip the helm_release and deploy via `helm-upgrade` instead (more consistent with the manual workflow).

Also add `DDI = "apps-designing-derobot-secrets"` to `app_db_secrets_map` in `main.tf:39` so the DB module provisions the credential secret.

Add the corresponding variables to `variables.tf` (domain, backend_image, frontend_image, tls_secret_name, chart_path) following the tobornalp block (lines 400-425).

Run: `cd terraform/kubernetes/apps/init && terragrunt apply` (requires MinIO port-forward + AWS creds per CLAUDE.md).

### Step 3 — Add Cloudflare DNS record for `designing.derobot.is`

In the `derobot.is` Cloudflare zone, add a CNAME record `designing.derobot.is` → the cluster ingress hostname (same target as `derobot.is` / other `*.derobot.is` subdomains). This is typically done via `terraform/cloudflare/zones/derobot.is/` or the Cloudflare dashboard. Verify an existing sibling record to match the target.

### Step 4 — Verify TLS cert coverage

Confirm the cert at Infisical `/apps/tls/derobotis` (`DEROBOTIS_TLS_CRT`/`DEROBOTIS_TLS_KEY`) covers `*.derobot.is` (wildcard). If it only covers the apex, create a new cert + Infisical path `/apps/tls/designing-derobot` and update `values.yaml` → `tls`.

### Step 5 — Build + push images

```bash
# From repo root (INFRA_ROOT)
docker-build --push designing.derobot.is/backend
docker-build --push designing.derobot.is/frontend
```
This tags both images as `v1.0.edge` (default), pushes to `ops.noizu.com`, and `docker-push` handles version assignment via Infisical.

For subsequent deploys where you want a pinned tag written into values.yaml:
```bash
docker-build --push --release designing.derobot.is/backend
docker-build --push --release designing.derobot.is/frontend
```

### Step 6 — Helm upgrade

```bash
helm-upgrade --include ddi
```
This resolves chart dir via `chart_path_overrides.ddi` (now fixed in step 1), namespace `apps-ns` (from override), tier 3, and runs `helm upgrade --install ddi <chart> -n apps-ns`.

Verify the plan first:
```bash
helm-upgrade --include ddi --preview    # diff vs live
helm-upgrade --include ddi --dry-run    # no apply
```

### Step 7 — Verify reachability

```bash
# Pods running
kubectl get pods -n apps-ns -l app.kubernetes.io/instance=ddi

# Ingress created
kubectl get ingress -n apps-ns

# DNS resolves
dig +short designing.derobot.is

# HTTPS responds
curl -sS -o /dev/null -w "%{http_code}\n" https://designing.derobot.is
curl -sS -o /dev/null -w "%{http_code}\n" https://api.designing.derobot.is   # if API subdomain is configured
```

### Step 8 — Run migrations (if not auto-run)

The chart has `migrate.enabled: true` which runs a Helm hook job. If it didn't run or failed:
```bash
liquibase-shell ddi    # uses .infra-config.yaml liquibase_targets.ddi (port 54338)
```

---

## 7. Risk notes

- **`--reset-values` default:** `helm-upgrade` passes `--reset-values` by default (helm-common.sh:665) so `values.yaml` is authoritative. Any manual `helm --set` overrides will be lost. This is the intended behavior.
- **Redis DB index 8:** ddi uses Redis DB `8` (`values.yaml` → `redis.db: 8`). Confirm no other app claims index 8 on `app-valkey`.
- **Secret name mismatch:** values.yaml says `secrets.name: apps-designing-derobot-secrets` but the DB secret is `ddi-secrets` (per liquibase target + app_db_secrets_map). These are two *different* secrets — the app reads its runtime secrets (DB creds, key base, etc.) from `apps-designing-derobot-secrets`, while `ddi-secrets` is the DB-credential secret used by the init/migration tooling. Ensure the InfisicalSecret CRD syncs `/apps/ddi` into `apps-designing-derobot-secrets` (the name the chart expects).
