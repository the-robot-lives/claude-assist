# Persistence Migration Runbook

Manual steps to complete the 3-tier persistence split after applying the terraform/infisical changes.

## Overview

The infra was refactored from a single shared `infra-timescaledb` + `shared-redis` into three tiers:

| Tier | PostgreSQL | Valkey | Namespace |
|------|-----------|--------|-----------|
| Infra | `infra-postgres` | `infra-valkey` | `infra` |
| Platform | `platform-postgres` | `platform-valkey` | `platform` |
| Apps | `app-postgres` | `app-valkey` | `apps` |

## Pre-Migration Checklist

- [ ] Port-forward to MinIO (`127.0.0.1:9000`) for Terraform state access
- [ ] Verify Infisical operator is running (`kubectl -n infra get pods -l app=infisical-operator`)
- [ ] Back up existing databases: `kubectl -n infra exec deploy/infra-postgres -c timescaledb -- pg_dumpall -U postgres > /tmp/pg_backup.sql`

## Phase 1: Seed Infisical Secrets

Push the new/updated credentials to Infisical so the operator can sync them into K8s Secrets.

```bash
infisical-populate-secrets
```

This seeds:
- `/apps/postgres` — new: superuser + 12 app credentials
- `/apps/valkey` — new: app-valkey password
- `/data/postgres` — updated: only 4 apps (authentik, infisical, phoenix, posthog)
- `/platform/postgres` — updated: expanded from 7 to 14 apps (added ghost, keygen, langfuse, n8n, plane, postiz, taiga)

## Phase 2: Apply Terraform

### 2a. Platform Init (creates platform-postgres + platform-valkey if not yet deployed)

```bash
cd terraform/kubernetes/platform/init
terragrunt apply
```

The `platform-postgres` deployment starts and runs initdb.d scripts for all 14 apps on first boot. If the PVC already exists from a prior run with the old name, you may need to handle the PVC rename or create a fresh one.

### 2b. Apps Init (creates app-postgres + app-valkey)

```bash
cd terraform/kubernetes/apps/init
terragrunt apply
```

Creates `app-postgres` and `app-valkey` in the `apps` namespace. The initdb.d scripts provision databases for all 12 portfolio apps on first boot.

### 2c. Infra (rename infra-timescaledb → infra-postgres)

```bash
cd terraform/kubernetes/infra
terragrunt apply -refresh=false -target=kubernetes_deployment_v1.postgres -target=kubernetes_service_v1.postgres
```

**Warning**: This renames the deployment and service. Apps referencing the old DNS name `infra-timescaledb.infra.svc.cluster.local` will break until they pick up the new connection strings from Infisical.

### 2d. Infra-Services (update connection strings)

```bash
cd terraform/kubernetes/infra-services
terragrunt apply
```

Rolls authentik, infisical, phoenix, and posthog pods with updated connection strings pointing to `infra-postgres`.

## Phase 3: Migrate Data

### 3a. Dump databases from infra-postgres

For each app being moved, dump its database from infra-postgres:

```bash
# Platform-tier apps to migrate
for db in bottlecrm docmost ghost keygen langfuse listmonk mermaid n8n nextcloud penpot plane postiz taiga webstudio; do
  kubectl -n infra exec deploy/infra-postgres -c timescaledb -- \
    pg_dump -U postgres -Fc "$db" > "/tmp/${db}.dump" 2>/dev/null && \
    echo "Dumped: $db" || echo "Skip (not found): $db"
done

# Apps-tier apps to migrate
for db in aifighter codefresh derobotis gotta_cc iotgo jailbreaking noizu_site start_app therobotknows therobotlives therobotplans tobornalp; do
  kubectl -n infra exec deploy/infra-postgres -c timescaledb -- \
    pg_dump -U postgres -Fc "$db" > "/tmp/${db}.dump" 2>/dev/null && \
    echo "Dumped: $db" || echo "Skip (not found): $db"
done
```

### 3b. Restore to platform-postgres

```bash
for db in bottlecrm docmost ghost keygen langfuse listmonk mermaid n8n nextcloud penpot plane postiz taiga webstudio; do
  [ -f "/tmp/${db}.dump" ] || continue
  kubectl cp "/tmp/${db}.dump" platform/$(kubectl -n platform get pod -l app.kubernetes.io/name=platform-postgres -o name | head -1 | cut -d/ -f2):/tmp/${db}.dump -c timescaledb
  kubectl -n platform exec deploy/platform-postgres -c timescaledb -- \
    pg_restore -U postgres -d "$db" --no-owner --role="$db" "/tmp/${db}.dump" && \
    echo "Restored: $db" || echo "Failed: $db"
done
```

### 3c. Restore to app-postgres

```bash
for db in aifighter codefresh derobotis gotta_cc iotgo jailbreaking noizu_site start_app therobotknows therobotlives therobotplans tobornalp; do
  [ -f "/tmp/${db}.dump" ] || continue
  kubectl cp "/tmp/${db}.dump" apps/$(kubectl -n apps get pod -l app.kubernetes.io/name=app-postgres -o name | head -1 | cut -d/ -f2):/tmp/${db}.dump -c timescaledb
  kubectl -n apps exec deploy/app-postgres -c timescaledb -- \
    pg_restore -U postgres -d "$db" --no-owner --role="$db" "/tmp/${db}.dump" && \
    echo "Restored: $db" || echo "Failed: $db"
done
```

### 3d. Migrate Valkey data (optional)

Valkey data is ephemeral cache — in most cases a clean start is fine. If you need to preserve data:

```bash
# Not typically needed — apps rebuild cache on restart
```

## Phase 4: Restart Application Pods

After data migration, restart pods so they pick up new connection strings:

```bash
# Platform-tier apps
for ns in platform; do
  kubectl -n "$ns" rollout restart deploy
done

# Apps-tier apps
kubectl -n apps rollout restart deploy

# Infra-services (already done by terraform apply, but verify)
kubectl -n infra rollout restart deploy/authentik-server deploy/authentik-worker
kubectl -n infra rollout restart deploy/phoenix
```

## Phase 5: Drop Migrated Databases from infra-postgres

After verifying all apps work on their new tier databases:

```bash
# Only after confirming apps are healthy on new databases!
for db in bottlecrm docmost ghost keygen langfuse listmonk mermaid n8n nextcloud penpot plane postiz taiga webstudio \
          aifighter codefresh derobotis gotta_cc iotgo jailbreaking noizu_site start_app therobotknows therobotlives therobotplans tobornalp; do
  kubectl -n infra exec deploy/infra-postgres -c timescaledb -- \
    psql -U postgres -c "DROP DATABASE IF EXISTS $db;" && \
    echo "Dropped: $db"
done
```

## Valkey DB Shard Assignments

### Platform Valkey

| DB | App |
|----|-----|
| /0 | Docmost |
| /1 | BottleCRM |
| /2 | Keygen |
| /3 | Penpot |
| /4 | Plane |
| /5 | Postiz |
| /6 | Excalidraw (configurable via `excalidraw_redis_db`) |
| /7 | Nextcloud |

### Apps Valkey

| DB | App |
|----|-----|
| /1 | AiFighter |
| /2 | Codefre.sh |
| /3 | Derobot.is |
| /4 | Gotta.cc |
| /5 | IoTGo |
| /6 | Jailbreaking |
| /7 | Start-App |
| /8 | (reserved) |
| /9 | TheRobotKnows |
| /10 | TheRobotLives |
| /11 | Tobornalp |
| /12 | TheRobotPlans |
| /13 | NoizuSite |

### Infra Valkey

Infra valkey uses ACL-based authentication (not DB number sharding). Each app gets its own ACL user.

| ACL User | App |
|----------|-----|
| `authentik` | Authentik |
| `infisical` | Infisical |
| `posthog` | PostHog |
| `default` | Health probes |

## Rollback

If migration fails, revert the connection strings by checking out the previous commit:

```bash
git checkout HEAD~1 -- .infisical-secrets.yaml
infisical-populate-secrets
# Re-apply terraform for each affected stack
```

The old databases remain on infra-postgres until Phase 5 explicitly drops them.
