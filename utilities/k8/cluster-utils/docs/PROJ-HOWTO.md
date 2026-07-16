# cluster-utils — How To

Task-oriented guides for the things you'll actually do with these `cluster-*` dashboards.
For *what it is* see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live* see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install cluster-utils and verify it works

**Goal:** Get `cluster-*` commands on your `PATH` and confirm they can reach your cluster.
**Prereqs:** `kubectl` configured with a working context; repo checked out.

1. Install the tools and the shared library together (run from the monorepo root):
   ```bash
   make install-utilities
   ```
   Or, to install just this package (you'll need `k8-lib` separately, see Gotchas):
   ```bash
   cd utilities/k8/cluster-utils && make install
   ```
2. Confirm the commands resolved:
   ```bash
   which cluster-status cluster-nodes cluster-helm
   ```

**Verify:** `cluster-status` prints a tiered, color-coded pod dashboard for your current
`kubectl` context.
**Gotchas:**
- Running `make install` from *this* directory alone does **not** install `k8-lib`. Every
  dashboard sources `~/.local/share/k8-lib` at runtime and errors immediately if it's
  missing — use `make install-utilities` from the monorepo root, or set `K8_LIB_DIR` to an
  existing checkout.
- No `infra-config.yaml` found is fine — tools fall back to built-in defaults.

## How to: check overall cluster health

**Goal:** See pod health across all namespaces, grouped by deployment tier, in one screen.
**Prereqs:** Installed per above; `kubectl` context pointed at the target cluster.

```bash
cluster-status              # one-shot dashboard
cluster-status --watch      # auto-refresh every 5s
```

**Verify:** Output groups pods by tier with red/yellow/green status coloring.
**Gotchas:** Tier groupings come from `infra-config.yaml`; without it, tools still run but
group less precisely — pass `--config <path>` to point at a specific file (see below).

## How to: inspect node capacity and pod placement

**Goal:** See CPU/RAM reservations per node, and optionally which pods run where.
**Prereqs:** Same as above.

```bash
cluster-nodes            # node summary: capacity type, CPU/RAM reservations
cluster-nodes --pods     # same, plus pod placement per node
```

**Verify:** Each node lists its capacity type (e.g. on-demand/spot) and reserved vs
available CPU/RAM.

## How to: check per-pod resource usage vs requests

**Goal:** Find pods using more CPU/RAM than they've requested (right-sizing, noisy-neighbor
hunts).
**Prereqs:** Cluster must have `metrics-server` installed.

```bash
cluster-resources
```

**Verify:** Output flags pods where live usage exceeds their request.
**Gotchas:** Fails/empty if `metrics-server` isn't installed — check with
`kubectl top nodes` first; if that errors, install `metrics-server` before this tool will
produce useful output.

## How to: review Helm release health

**Goal:** Spot failed/pending Helm releases across the cluster at a glance.

```bash
cluster-helm
```

**Verify:** Releases in a non-`deployed` state are color-highlighted.

## How to: generate a markdown snapshot of the cluster layout

**Goal:** Produce a shareable, versionable markdown doc of node→pod placement and
PVC→PV storage mapping — e.g. to paste into an incident writeup or commit as documentation.
**Prereqs:** [`glow`](https://github.com/charmbracelet/glow) optional, for pretty terminal
rendering.

```bash
cluster-layout                              # render in terminal (pipes to glow if present)
cluster-layout > .tmp/cluster-layout.md     # save the markdown instead
```

**Verify:** Output/file is valid markdown with node pool groupings, pod placement, and a
PVC→PV storage table.
**Gotchas:** Node pool labels default to `general=karpenter,indexer=karpenter:indexer,managed=eks`;
override with `K8_NODEPOOL_LABELS` if your pools are named differently.

## How to: check Manticore Search cluster status

**Goal:** See reader pod status, index versions, S3 index state, and recent job history for
a Manticore Search deployment.

```bash
cluster-manticore
```

**Verify:** Dashboard lists readers, their index versions, and S3/job state.
**Gotchas:** Requires AWS credentials with read access to the index bucket
(`K8_MANTICORE_S3_BUCKET`, default `manticore-indexes`) — `aws s3` calls will fail silently
into empty sections otherwise.

## How to: get AI-assisted help from any tool

**Goal:** Ask a question about what a dashboard is showing you, without leaving the
terminal — every `cluster-*` tool (except `cluster-setup-telemetry`, see below) supports
this.
**Prereqs:** Claude Code CLI (`claude`) installed and on `PATH`.

```bash
cluster-status --assist "why is the apps-ns tier showing red?"
cluster-nodes --assist "which node has the most spare CPU?"
```

**Verify:** Instead of the normal dashboard, the tool prints an AI-generated answer using
the tool's own output as context.
**Gotchas:** Errors with `claude CLI not found` if Claude Code isn't installed — this is a
convenience layer, not a hard dependency for normal dashboard use.

## How to: point a tool at a non-default config file

**Goal:** Run any dashboard against tier groupings/status patterns from a specific
`infra-config.yaml` instead of the auto-discovered one (e.g. testing a config change, or
running against a second cluster's config).

```bash
cluster-status --config /path/to/other-infra-config.yaml
cluster-helm --config=/path/to/other-infra-config.yaml
```

**Verify:** Dashboard output reflects the tiers/patterns from the specified file.
**Gotchas:** `--config` must be parsed before other flags take effect since it controls
which library config loads — put it first if combining with other flags
(e.g. `cluster-nodes --config <path> --pods`).

## How to: install telemetry collection on a VM/EC2 host

Bootstrap OTel Collector + Fluent Bit on a non-Kubernetes host and point it at a central
OTLP endpoint, with auto-detected service scraping (PostgreSQL, MySQL, Nginx, Redis, Docker).
→ *See [howto/setup-telemetry.md](howto/setup-telemetry.md)*
