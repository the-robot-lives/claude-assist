# How-To — utilities/k8

Task-oriented guides for **cross-tool workflows** in the k8s DevOps toolset —
the sequences that span two or more of the seven packages, plus the
"which tool do I reach for" questions a new user hits first. Each package
documents its own internals in its own `docs/PROJ-HOWTO.md`; this file links
out rather than repeating them. See [PROJ-ARCH.md](PROJ-ARCH.md) for *why* the
tools are shaped this way and [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where*
things live.

## How to: install every k8s tool at once

**Goal:** get all seven packages (`k8-lib` + six tool CLIs) on `PATH` in one command.
**Prereqs:** repo cloned; `make` available.

1. From the **repo root** (not `utilities/k8/`):
   ```bash
   make install-utilities
   ```
   This fans out to every child's `make install` via `utilities/k8/Makefile` →
   `../mk/subdirs.mk`, installing `k8-lib` to `~/.local/share/k8-lib` and every
   CLI flat into `~/.local/bin`.

**Verify:**
```bash
which docker-build docker-push helm-upgrade cluster-status staging-up infisical deploy-service
```
All should resolve under `~/.local/bin`.

**Gotchas:**
- `~/.local/bin` not on `PATH` → tools install but `which` fails; add it to your shell rc.
- Need just one package reinstalled after a local edit? `cd utilities/k8/<package> && make install` — no need to rerun the full fan-out.
- Per-package first-run details (config file, credentials) live in each
  package's own install guide — see the table below.

## How to: run the full build → push → deploy pipeline

**Goal:** ship a code change all the way to the cluster with one command.
**Prereqs:** `deploy-service` on `PATH` (infra-utils); image key registered in `.infra-config.yaml`.

1. ```bash
   deploy-service <image-key>
   ```
   This composes three packages in sequence: `docker-build`/`docker-push`
   (docker-utils) → chart `values.yaml` tag bump → `helm-upgrade` (helm-utils),
   honoring `.infra-config.yaml` tier order the whole way.

**Verify:** `helm-upgrade --list` shows the release with the new image tag; `cluster-status` shows healthy pods for it.

**Gotchas:**
- Multiple images sharing one Helm release (frontend+backend) → see infra-utils'
  [deploy a composite project](../infra-utils/docs/PROJ-HOWTO.md) guide, not one `deploy-service` call per image.
- Something in the pipeline errors opaquely → infra-utils'
  [troubleshoot-deploy-service.md](../infra-utils/docs/howto/troubleshoot-deploy-service.md)
  decodes the four most common failures.
- Want to see the pipeline's effect before it happens? `deploy-service <key> --dry-run`.

## How to: pick the right tool for a task

**Goal:** know which of the seven packages to reach for without reading all seven READMEs.

| I want to… | Use | Docs |
|---|---|---|
| Build/push a Docker image | `docker-build` / `docker-push` | [docker-utils](../docker-utils/docs/PROJ-HOWTO.summary.md) |
| Deploy/upgrade a Helm chart | `helm-upgrade` | [helm-utils](../helm-utils/docs/PROJ-HOWTO.summary.md) |
| Roll back a bad deploy | `helm-rollback` | [helm-utils](../helm-utils/docs/PROJ-HOWTO.summary.md) |
| Do build+push+deploy in one shot | `deploy-service` | [infra-utils](../infra-utils/docs/PROJ-HOWTO.summary.md) |
| Register a new image/chart in config | `infra-config` | [infra-utils](../infra-utils/docs/PROJ-HOWTO.summary.md) |
| Check cluster/pod/node health | `cluster-status` / `cluster-nodes` / `cluster-resources` | [cluster-utils](../cluster-utils/docs/PROJ-HOWTO.summary.md) |
| Snapshot the cluster layout to markdown | `cluster-layout` | [cluster-utils](../cluster-utils/docs/PROJ-HOWTO.summary.md) |
| Manage secrets (rotate, verify, populate Infisical) | `infisical` (or legacy `infisical-*` scripts) | [secret-utils](../secret-utils/docs/PROJ-HOWTO.summary.md) |
| Stand up/tear down the staging environment | `staging-up` / `staging-down` | [staging-utils](../staging-utils/docs/PROJ-HOWTO.summary.md) |
| Bootstrap Terraform + submodules on a fresh clone | `infra-init` | [infra-utils](../infra-utils/docs/PROJ-HOWTO.summary.md) |
| Change how any tool resolves config/credentials | (nothing to run — it's shared) | [k8-lib](../k8-lib/docs/PROJ-HOWTO.summary.md) |

**Gotchas:**
- If two rows look equally right, prefer the composed tool (`deploy-service`) over
  running the lower-level tools by hand — it keeps tier ordering and state
  files (`.docker-state/`, `.helm-state/`) consistent.

## How to: ask any tool for AI-assisted help without leaving the terminal

**Goal:** get a natural-language answer sourced from a script's own usage/header, on any package.
**Prereqs:** none beyond the tool being installed; uses headless Claude Code under the hood.

1. Append `--assist "<question>"` to almost any command in this toolset:
   ```bash
   cluster-status --assist "why would this show a pod as Pending forever?"
   helm-upgrade --assist "how do I upgrade just one release?"
   ```

**Verify:** an in-terminal answer appears, grounded in that script's own header comment and (where relevant) its live output.

**Gotchas:**
- This is a shared convention implemented once in k8-lib, not a per-tool
  reimplementation — see k8-lib's
  [Add `--assist` support to a new script](../k8-lib/docs/PROJ-HOWTO.summary.md)
  guide if you're wiring it into a new script rather than just using it.

## How to: recover a cluster's Helm releases in the right order after a disaster

**Goal:** re-deploy all releases on a fresh or recovered cluster without dependency-order mistakes.
**Prereqs:** Infisical reachable and tier-0 secrets bootstrapped; kube context set.

1. Bootstrap the secrets tier Infisical itself needs first (secret-utils):
   ```bash
   infisical-bootstrap
   ```
2. Re-deploy every release in `.infra-config.yaml` tier order (infra-utils):
   → see infra-utils'
   [recover/bootstrap a cluster's Helm releases in order](../infra-utils/docs/PROJ-HOWTO.md) guide for the exact command and tier semantics.

**Verify:** `cluster-status` shows every tier healthy, lowest tier first.

**Gotchas:**
- Skipping step 1 is the most common failure mode — tier 0 (`infisical`
  namespace) must be healthy before anything depending on synced k8s Secrets
  can come up.

## Sharp edges: config resolution is shared, not per-tool

**Goal:** understand why overriding `--config`, `K8_*`, or `.envrc.k8.dc` affects every tool identically.

All seven packages resolve structural config (`.infra-config.yaml`) and scalar
config (env-first: `K8_*` → `dc get` → YAML → default) through the same
k8-lib facade — there is no per-package config format. If a value looks wrong
in one tool, check k8-lib's resolution order and
["config not found" / yq errors](../k8-lib/docs/PROJ-HOWTO.summary.md) guide
first; the fix is almost never tool-specific.

**Gotchas:**
- Multiple `.infra-config.yaml` files in a repo (e.g. a nested project) →
  discovery walks `--config` → `$K8_CONFIG` → `$INFRA_ROOT` → git-root; an
  unexpected file wins if it's closer to your `cwd`.
