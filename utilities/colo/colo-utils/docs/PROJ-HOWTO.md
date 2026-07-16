# colo-utils — How-To Guides

Task-oriented guides for the things you'll actually do with this package. See [PROJ-ARCH.md](PROJ-ARCH.md) for *what it is* and [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where things live*.

## How to: install the tools

**Goal:** get `cluster-*` and `colo-*` commands on your `PATH`.
**Prereqs:** `kubectl` + cluster access for `cluster-*`; `helm`; `glow` (optional, for `cluster-layout`).

1. `colo-*` helpers only (this package):
   ```bash
   make install    # → ~/.local/bin (INSTALL_DIR override supported)
   ```
2. `cluster-*` dashboards + `k8-lib` (from the monorepo root):
   ```bash
   make install-utilities
   ```

**Verify:** `cluster-status` prints a tiered pod table; `colo-sync --help` prints usage.
**Gotchas:**
- `make install` in this dir installs **only `colo-*`** — running `cluster-status` right after gives "command not found" until you also run `make install-utilities` from the repo root, or invoke it directly as `bin/cluster-status`.
- No `kubectl` context configured → `cluster-*` tools error immediately; run `kubectl config current-context` first.

## How to: check overall cluster pod health

**Goal:** see every pod's status, grouped by deployment tier, with problems highlighted red/yellow.
**Prereqs:** `kubectl` context set to the target cluster.

```bash
cluster-status              # one-shot snapshot
cluster-status --watch      # auto-refresh every 5s
cluster-status --config /path/to/infra-config.yaml   # alternate config
```

**Verify:** output groups pods by tier (0-9) with color-coded status; non-Running pods stand out.
**Gotchas:** without an `infra-config.yaml` (repo-root default or `--config`), tier grouping falls back to defaults — pods still show, just ungrouped by your custom tiers.

## How to: inspect node capacity and placement

**Goal:** see CPU/RAM reservations per node, and optionally which pods sit where.
**Prereqs:** `kubectl` context set.

```bash
cluster-nodes            # node summary: capacity type, CPU/RAM reservation
cluster-nodes --pods     # same, plus per-node pod placement
```

**Verify:** each node row shows spot/on-demand capacity type and reservation percentages.
**Gotchas:** reservation % reflects requests, not live usage — use `cluster-resources` for actual usage.

## How to: check pod resource usage vs requests

**Goal:** spot pods using far more (or less) than they requested.
**Prereqs:** `metrics-server` installed in the cluster.

```bash
cluster-resources
```

**Verify:** table lists CPU/RAM usage next to requested values per pod.
**Gotchas:** empty or errored output almost always means `metrics-server` isn't installed or hasn't warmed up yet — check with `kubectl top nodes`.

## How to: check Helm release health

**Goal:** see every Helm release's status at a glance, failures highlighted.
**Prereqs:** `helm` on `PATH`, cluster access.

```bash
cluster-helm
```

**Verify:** releases in a failed/pending state are colored distinctly from `deployed`.

## How to: view full cluster storage/node layout

**Goal:** a single rendered-markdown view of nodes, PVCs, and PVs.
**Prereqs:** `glow` installed (optional — falls back to raw markdown on stdout without it).

```bash
cluster-layout | glow -    # rendered
cluster-layout             # raw markdown if glow isn't installed
```

## How to: check Manticore Search cluster state

**Goal:** dashboard of Manticore readers, indexes, S3 backend state, and running jobs.
**Prereqs:** Manticore deployed in-cluster, `kubectl` access.

```bash
cluster-manticore
```

## How to: sync files with the colo server

**Goal:** push or pull files between your machine and `noizu.server` with automatic `/Users` ↔ `/home` path mirroring.
**Prereqs:** SSH access to `noizu.server` as `$COLO_USER` (default `keith`).
→ *See [howto/sync-with-colo-server.md](howto/sync-with-colo-server.md)*

## How to: keep an SSH tunnel open to the colo local-model port

**Goal:** a persistent, auto-restarting reverse tunnel from `noizu.server:3713` to your Mac, managed as a LaunchDaemon.
**Prereqs:** macOS, sudo access, SSH identity + known_hosts already trusting the colo server.
→ *See [howto/local-model-tunnel.md](howto/local-model-tunnel.md)*

## How to: install telemetry on a new VM/EC2 host

**Goal:** stand up OTel Collector + Fluent Bit on a non-cluster host, auto-detecting local services and pointing at a central OTLP endpoint.
**Prereqs:** root/sudo on the target host; run *on* that host, not your dev machine.
→ *See [howto/setup-vm-telemetry.md](howto/setup-vm-telemetry.md)*

## How to: wire up the deploy relay on the colo server

**Goal:** have the colo server pull GitHub Deployments every 60s and run `helm-upgrade` automatically, with no inbound webhook needed.
**Prereqs:** `gh`/GitHub token with deployments access, `helm-upgrade` utility installed, systemd on the target host.
→ *See [howto/deploy-relay-setup.md](howto/deploy-relay-setup.md)*
