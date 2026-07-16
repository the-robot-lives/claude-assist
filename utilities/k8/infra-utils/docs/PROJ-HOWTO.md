# infra-utils — How To

Task-oriented guides for the six `bin/` CLIs. For *what these tools are*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where files live*, see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the commands

**Goal:** get `deploy-service`, `infra-config`, `infra-init`, `deploy-one-off`,
`open-dashboard`, `add-import-permissions` on your `PATH`.
**Prereqs:** `terraform`, `kubectl`, `aws`, `git`, `docker-build`, `helm-upgrade`, `yq`.

```bash
cd utilities/k8/infra-utils
make install                     # installs to ~/.local/bin (INSTALL_DIR override supported)
```

Normally run via the repo-wide `make install-utilities` instead of calling this directly.

**Verify:** `command -v deploy-service infra-config infra-init`
**Gotchas:**
- Missing `yq`/`helm-upgrade`/`docker-build` on `PATH` → each script fails fast naming the
  missing dependency; install the sibling `utilities/` package first.

## How to: bootstrap a fresh checkout with infra-init

**Goal:** get Terraform initialized and git submodules hydrated on a new machine/clone.
**Prereqs:** `terraform`, `git`; AWS creds if running Terraform against real state.

```bash
infra-init doctor      # check config + tool health first
infra-init repos       # hydrate git submodules
infra-init terraform   # terraform init against the resolved state backend
# or just:
infra-init all         # repos then terraform
```

**Verify:** `infra-init doctor` reports no missing tools/config.
**Gotchas:**
- `infra-init` is a pure dispatcher — real logic lives in k8-lib `cmd_*` functions; if a
  subcommand behaves unexpectedly, the fix is almost always in `k8-lib`, not here.

## How to: import existing AWS infrastructure via Terraformer

**Goal:** bring already-created AWS resources under Terraform management.
→ *See [howto/terraformer-import.md](howto/terraformer-import.md)*

## How to: deploy a single service image

**Goal:** build, push, bump the chart's `values.yaml`, and helm-upgrade one release, in
one command.
**Prereqs:** the image key has a `helm:` stanza under `project.docker.images[]` in a
`project.yaml` (see *wire a new project*, below) — `chart_path`, `values_path`, `format`.

```bash
deploy-service easy-peasy               # build → push → bump values → helm upgrade
deploy-service easy-peasy --dry-run     # print the plan; touch nothing
```

**Verify:** `helm-upgrade --include <release>` shows the new tag deployed; `git diff` on
the chart's `values.yaml` shows the bumped tag if you inspect before commit.
**Gotchas:**
- `No project.yaml declares helm for image` → the image key isn't wired up yet; see
  *wire a new project* below.
- `Could not reverse-map chart_path` → `helm.chart_path` in the image's `helm:` stanza
  must equal `PROJECT_DIR/helm.path` from the project-level stanza, exactly.

## How to: deploy a composite project (multiple coupled services)

**Goal:** ship a backend+frontend pair (or more) that share one Helm release with a
single `helm-upgrade` call, not one per image.

```bash
deploy-service codefre.sh/backend codefre.sh/frontend
```

Each image's `values_path` is bumped, then unique releases are deduped and upgraded once.
Requires the `type: composite` shape in `project.yaml` — see the README's "Composite
Project YAML" section for the full stanza.

**Verify:** only one `helm upgrade` line appears in the output even with 2+ image keys.
**Gotchas:**
- Mixing image keys that map to different releases is fine — each gets its own upgrade —
  but a typo in `values_path` per-service silently bumps the wrong key; check with
  `deploy-service ... --dry-run` first.

## How to: control what a deploy actually does

**Goal:** stage, promote, or partially run a deploy without the full build+push+upgrade.

```bash
deploy-service my-app --stage              # BUILD_ENV=stage
deploy-service my-app --prod               # BUILD_ENV=prod
deploy-service my-app --skip-build         # deploy current values.yaml as-is
deploy-service my-app --skip-deploy        # build+push+bump only, no helm-upgrade
deploy-service my-app --tag v2.1.0         # force the edge build tag (single key only)
deploy-service my-app --yes                # headless: auto-confirm push + upgrade prompts
```

**Verify:** combine with `--dry-run` first to confirm the intended flags took effect.
**Gotchas:** `--tag` is rejected when more than one image key is given — pin one at a time.

## How to: wire a new project into .infra-config.yaml

**Goal:** register a new Docker image (standalone or composite) and its Helm deploy
target so `deploy-service <key>` works.
→ *See [howto/wire-new-project.md](howto/wire-new-project.md)*

## How to: manage helm-dir, helm-alias, and timeout overrides

**Goal:** register a Helm scan directory, alias a chart's path, or override a release's
upgrade timeout, without hand-editing `.infra-config.yaml`.
→ *See [howto/manage-infra-config-overrides.md](howto/manage-infra-config-overrides.md)*

## How to: preview an infra-config change before writing it

**Goal:** see the exact diff `infra-config add/remove` would make, without touching the
file.

```bash
infra-config add helm-dir kubernetes/helm/creative --dry-run
infra-config add namespace my-app apps-ns --dry-run
```

Drop `--dry-run` and add `--yes`/`-y` to apply headlessly (e.g. from a script); omit both
to get an interactive `Apply this change? [y/N]` prompt with the diff shown first.

**Verify:** dry-run output ends with `[dry-run] No changes written.`
**Gotchas:** `--config PATH` must come before `infra-config` resolves the file if you're
not running from the infra root — otherwise it edits the wrong `.infra-config.yaml`.

## How to: open a monitoring dashboard

**Goal:** reach Goldilocks, Kubecost, Parca, or SigNoz locally via port-forward.

```bash
open-dashboard goldilocks   # VPA recommendations, localhost:8080
open-dashboard kubecost     # cost allocation, localhost:9090
open-dashboard parca        # continuous profiling, localhost:7070
open-dashboard signoz       # traces/metrics, localhost:3301
```

**Verify:** browser opens automatically; `Ctrl-C` stops the port-forward.
**Gotchas:** wrong namespace/service name → override with `K8_{TOOL}_NS` /
`K8_{TOOL}_SVC` env vars (e.g. `K8_KUBECOST_NS=cost-ns open-dashboard kubecost`).

## How to: grant the Terraformer import user its IAM permissions

**Goal:** sync the `terraformer-import` AWS user's inline policy to the canonical JSON
checked into `terraform/production/imported/iam/terraformer-import-policy.json`.

```bash
add-import-permissions --dry-run            # show action count, apply nothing
add-import-permissions --profile terraformer
```

**Verify:** `aws iam get-user-policy --user-name terraformer-import --policy-name TerraformerImportPolicy --profile terraformer`
matches the local JSON.
**Gotchas:** `POLICY_FILE not found` → you're not running from the infra root, or the
canonical policy file moved; `INFRA_ROOT` overrides the search base.

## How to: recover/bootstrap a cluster's Helm releases in order

**Goal:** re-deploy releases in the correct dependency order (infra → stateful → apps)
after a disaster-recovery scenario or fresh cluster.
**Prereqs:** `helm-upgrade` on `PATH`; read `bin/deploy-one-off` first — it is a
*template*, not a runnable script.

1. Open `bin/deploy-one-off` and read the ordered, commented `helm-upgrade` invocations.
2. Uncomment/edit the steps for your actual recovery scenario.
3. Run the edited copy manually, verifying each tier before moving to the next.

**Verify:** each `helm-upgrade --include <release>` step succeeds before the next runs.
**Gotchas:** don't run this file unedited — it's intentionally not automated so a bad
guess doesn't cascade through every tier unattended.

## How to: get AI-assisted help without leaving the terminal

**Goal:** ask a natural-language question about any script's usage and get an answer
sourced from its own header comment.

```bash
deploy-service --assist "how do I ship just the frontend without a helm upgrade?"
infra-config --assist "how do I alias a chart path?"
```

**Verify:** requires the `claude` CLI on `PATH`; errors clearly if it's missing.
**Gotchas:** `--assist` short-circuits the rest of the command — no other flags run
alongside it.

## Troubleshooting deploy-service failures

**Goal:** decode the four most common `deploy-service` errors fast.
→ *See [howto/troubleshoot-deploy-service.md](howto/troubleshoot-deploy-service.md)*
