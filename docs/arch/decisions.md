# Key Architecture Decisions

Brief rationale for the load-bearing choices. Not a full ADR log — see project-specific docs
and git history for finer detail.

## Provisioning & platform

- **OpenTofu over Terraform** — open-source binary (`tofu`), no licensing constraints; driven
  by Terragrunt for DRY multi-stack orchestration with explicit dependency ordering.
- **MinIO-hosted tfstate (self-referential bootstrap)** — the cluster hosts its own S3-compatible
  state backend, so `init` runs on local state to create the bucket the rest depend on. Keeps
  state in-cluster with no external cloud dependency.
- **Git subtrees, not submodules** — portfolio projects and vendored 3rd-party sources are
  vendored as subtrees so the monorepo builds without recursive clones/auth, while still being
  pushable upstream (`push-subtrees.sh`).

## Secrets

- **Infisical as the runtime secret authority** — declarative `.infisical-secrets.yaml` →
  Infisical → operator-synced K8s Secrets → Helm. Charts never embed secret values.
- **Layered credential sources (`dc → override → auto → default`)** — `direnv-config` (`dc`)
  provides an encrypted, version-controllable local layer (`.envrc.dc`) that maps to Infisical
  names, so provisioning and secret population share one source. Pin real values in `.envrc.dc`
  rather than relying on `auto`-generated passwords.

## Deployment

- **`values.yaml` authoritative (`helm-upgrade --reset-values` default)** — prevents stale
  live-release values from masking config changes (the classic "image didn't update"); opt out
  per release via `helm_preserve_values`.
- **Tiered rollout** — ordering by dependency tier (secrets → data/observability → platform →
  apps → creative/AI) ensures backing stores and auth exist before dependents start.
- **Liquibase for schema, not ORM migrations** — DB changes are Liquibase changelogs
  (`liquibase_targets`), decoupling schema from any single app's migration runner.

## Data layer

- **3-tier database split (Postgres / Valkey)** — separate instances per tier isolate blast
  radius and let data/platform/app workloads scale and rotate credentials independently.
  → detail: [../infrastructure-topology.md](../infrastructure-topology.md) §3–4

## Application scaffold

- **start-app as the canonical app template** — Elixir/Phoenix backend + Next.js frontend +
  Helm chart. Portfolio sites are (re)scaffolded from it for consistency; the Noizu Elixir
  framework ecosystem (genai, noizu_labs_*, entities, services) underpins the backends.
