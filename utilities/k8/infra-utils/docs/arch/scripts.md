# Script Reference

## bin/deploy-service

Headless release pipeline: build → multi-arch push → values.yaml bump → helm upgrade.

Usage: `deploy-service <image-key> [<image-key>...] [flags]` — image keys are flat
(`bottlecrm`) or composite (`codefre.sh/backend`), resolved exactly as `docker-build`
resolves them. Each key must have a `helm:` stanza in the merged `.infra-config.yaml`
(`.project.docker.images[].helm` or `.project.projects[].services[].helm`):

| Field | Purpose |
|-------|---------|
| `chart_path` | Directory holding the target `values.yaml` (repo-root-relative) |
| `values_path` | `yq` path to rewrite inside `values.yaml` |
| `format` | `tag` (bare version string, default) or `image` (full ref; only the tag is swapped) |

Flow: derive edge tag `v<M>.<m>.edge[-env]` from the tag currently in values.yaml (or
`--tag`), run `docker-build --push --multiarch --vsn <edge>`, read the promoted tag from
k8-lib's `.docker-state/pushes` ledger, `yq -i` the values file, then run
`helm-upgrade --include <chart>` once per unique release (release = `basename(chart_path)`).

| Flag | Purpose |
|------|---------|
| `--tag TAG` | Force edge tag (single key only) |
| `--dev` / `--stage` / `--prod` / `--env ENV` | Set `BUILD_ENV` (default `dev`) |
| `--no-cache` | Pass through to `docker-build` |
| `--skip-build` | Deploy current values.yaml as-is (no build/push/bump) |
| `--skip-deploy` | Build + push + bump only |
| `--yes`, `-y` | Headless: auto-confirm docker push + helm-upgrade |
| `--dry-run` | Print plan; touch nothing |
| `--config PATH` | Explicit `.infra-config.yaml` |

Sources k8-lib `common.sh`, `docker-config.sh`, `helm-common.sh`, `assist.sh`. Warns when
a chart is not discoverable by helm-upgrade (`paths.helm_dir` / `helm_scan_dirs` /
`chart_path_overrides`).

## bin/infra-config

CRUD (`list` / `add` / `remove`) for `.infra-config.yaml` resources, edited via `yq`:

| Resource | Target |
|----------|--------|
| `helm-dir` | `helm_scan_dirs[]` |
| `helm-alias` | `chart_path_overrides` (chart → path) |
| `namespace` / `timeout` | `namespace_overrides` / `timeout_overrides` (chart → value) |
| `tier-chart` | `tiers[].charts[]` (with `--tier N`) |
| `docker-image` / `docker-dir` | `project.docker.images[]` (dir shorthand derives name) |
| `project` / `service` / `docker-group` | `project.projects[]` composite entries |

Flags: `--config PATH`, `--dry-run`, `--yes`, `--assist "Q"`.

## bin/infra-init

Multi-command CLI for developer environment setup and infrastructure import.

| Subcommand | Purpose |
|------------|---------|
| `terraform` | Initialize Terraform provider plugins and run `terraform init` |
| `repos` | Hydrate git submodules |
| `all` | Run `repos` then `terraform` |
| `import` | Batch import existing AWS infrastructure via Terraformer (skips already-imported; `--force` to re-import) |
| `cleanup` | Strip invalid Terraformer attributes + AWS CLI spot-checks |
| `state-upgrade` | Migrate Terraformer legacy provider state to TF 1.x format |
| `doctor` | Verify tooling and configuration health |

Sources shared functions from `share/k8-lib/bin/*.sh` (resolved relative to script location).

## bin/deploy-one-off

A **template** (not executable as-is) documenting the canonical Helm deployment order for disaster recovery or initial cluster bootstrapping:

1. Uncordon managed nodes
2. Infrastructure caches (Redis)
3. Infrastructure databases (TimescaleDB)
4. Secrets manager (Infisical)
5. Observability stack (SigNoz)
6. Application caches and databases
7. Read replicas and connection poolers
8. Primary database (last, since everything depends on it)
9. Stateless application services (rolling update)
10. Search / auxiliary services
11. Placement verification (managed nodes + Karpenter nodes)

Namespace controlled by `K8_NAMESPACE` (default: `default`).

## bin/open-dashboard

Port-forwards to cluster monitoring dashboards.

| Dashboard | Default Namespace | Default Service | Local Port |
|-----------|-------------------|-----------------|------------|
| `goldilocks` | `goldilocks` | `goldilocks-dashboard` | 8080 |
| `kubecost` | `kubecost` | `kubecost-cost-analyzer` | 9090 |
| `parca` | `parca` | `parca-server` | 7070 |
| `signoz` | `infra` | `signoz-frontend` | 3301 |

All values overridable via `K8_{TOOL}_NS` and `K8_{TOOL}_SVC` environment variables.

## bin/add-import-permissions

Applies the Terraformer IAM policy to the `terraformer-import` AWS IAM user. Reads the policy JSON from `terraform/production/imported/iam/terraformer-import-policy.json`.

| Flag | Purpose |
|------|---------|
| `--profile PROFILE` | AWS CLI profile (default: `$PROFILE` or `$K8_AWS_PROFILE` or `terraformer`) |
| `--dry-run` | Print what would be applied without making changes |
