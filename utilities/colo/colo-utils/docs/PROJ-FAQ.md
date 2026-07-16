# colo-utils — FAQ

Answers to the *why/when/compared-to-what* questions. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for procedures and [PROJ-ARCH.md](PROJ-ARCH.md) for design rationale.

## Motivation

### Why would I use `colo-sync` instead of just running `rsync` myself?

Because it saves you from remembering (and mistyping) the remote path. `noizu.server` mirrors your Mac's `/Users/<user>/...` tree under `/home/<user>/...`, and `colo-sync` derives one side from the other automatically in single-flag mode — you pass one path, not two. It also bakes in a stable default exclude list (`node_modules`, `.venv`, `_build`, `.terraform`, `dist`) so you don't re-type them every invocation. If your layout genuinely diverges between machines, two-flag mode (`--from`/`--to` both explicit) falls back to plain rsync semantics.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-sync-files-with-the-colo-server) to do it.*

### Why does `colo-deploy-relay` poll GitHub instead of receiving a webhook?

Because the colo server has no inbound access exposed, by design. A webhook would require opening a port and terminating auth on a box that otherwise only makes outbound connections. Polling every 60s costs a small latency tax (worst case ~60s to notice a new deployment) in exchange for zero attack surface on the receiving end.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

### Why is the local-model tunnel a LaunchDaemon instead of a terminal `ssh -R` I run by hand?

Because a foreground SSH session dies with your terminal, your laptop sleep, or a dropped Wi-Fi hop — exactly the moments you don't want to notice you lost the tunnel. The LaunchDaemon survives reboots and auto-reconnects on drop; the trade-off is that it's a persistent background process needing sudo to install/manage rather than something you can Ctrl-C.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-keep-an-ssh-tunnel-open-to-the-colo-local-model-port).*

### Why does `make install` in this directory only install `colo-*` tools, not `cluster-*`?

Because the two families have different homes: `colo-*` (deploy relay, tunnel, sync) are specific to this package and the colo server, while `cluster-*` dashboards ship alongside `k8-lib` through the monorepo's own `make install-utilities` so they stay versioned with the shared library they depend on. The split means a fresh clone of just this package can't run `cluster-status` until you also install from the repo root — that's the intended boundary, not a bug, but it does mean the first "command not found" surprises people expecting one `make install` to cover everything.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-the-tools) and [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

## Fit

### When should I reach for `cluster-status`/`cluster-nodes`/etc. instead of raw `kubectl get pods`?

When you want tier-grouped, color-coded, at-a-glance triage rather than a flat list you have to scan by eye. They're dashboards, not a `kubectl` replacement — `cluster-resources` still just wraps `kubectl top`-adjacent data, and for anything ad-hoc (one-off `describe`, `logs -f`, `exec`) plain `kubectl` remains faster than reaching for a dashboard.

### Is `colo-local-model-link` any use if I'm not on macOS?

No. It calls `require_macos` and refuses to run on Linux or anything else — LaunchDaemons are a macOS-only mechanism and there is no systemd/other equivalent shipped in this package. If you need the same reverse tunnel from Linux, you'd manage it with your own systemd user unit; nothing here does that for you today.

### Should I run `cluster-setup-telemetry` on my own dev machine?

No — it's meant for a target VM/EC2/bare-metal host you're onboarding into telemetry, and it installs system services (`signoz-otel-collector`, Fluent Bit) requiring root. Running it against your laptop would install monitoring daemons you almost certainly don't want there.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-telemetry-on-a-new-vmec2-host).*

## Comparison

### How does `colo-utils` differ from `k8-lib`?

`k8-lib` is the shared shell library (config resolution, color/formatting helpers, the `--assist` hook) that other utilities in the monorepo also depend on; `colo-utils` is a consumer package of two tool families (`cluster-*` dashboards, `colo-*` colo-server helpers) that source `k8-lib` when available but degrade gracefully without it. You'd modify `k8-lib` to change shared behavior across all utilities; you'd modify `colo-utils` to change what these specific dashboards/helpers do.

### How does `cluster-nodes` differ from `cluster-resources` — don't they both show usage?

No — `cluster-nodes` shows *reservations* (what's been requested/allocated against node capacity), while `cluster-resources` shows *live usage* (what pods are actually consuming right now, via `metrics-server`). A node can read 90% reserved in `cluster-nodes` while sitting at 20% real utilization in `cluster-resources` if pods requested generously but aren't using it — reach for `cluster-nodes` to plan capacity/bin-packing and `cluster-resources` to right-size requests or chase a noisy-neighbor pod.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-inspect-node-capacity-and-placement) and [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-check-pod-resource-usage-vs-requests).*

### How is `colo-deploy-relay` different from a normal CI/CD push-based deploy?

A conventional pipeline pushes to the target (SSH, webhook, kubectl from a runner with cluster creds); `colo-deploy-relay` inverts that — the colo server pulls GitHub Deployments on its own schedule and applies them locally via `helm-upgrade`. You get at-most-60s latency and no runner needing direct network access to the colo server's cluster, at the cost of it not being instantaneous like a push trigger.

## Capability

### Can `colo-sync`/`cluster-*` run without `k8-lib` installed?

Yes for `colo-sync` and the deploy relay — they source `k8-lib`'s `assist.sh` conditionally and just lose the `--assist` AI-help hook if it's absent. `cluster-*` dashboards similarly degrade for config resolution (falling back to built-in tier/status defaults) but still run. `cluster-setup-telemetry` is explicitly designed to run on remote VMs with no `k8-lib` at all.

### Can `colo-deploy-relay` recover if I delete its state file?

Not cleanly — `last-deployment-id` in `STATE_DIR` is the *only* checkpoint. Deleting it doesn't crash the relay; it replays **every** deployment ever created for that environment on the next cycle, which will re-run `helm-upgrade` for all of them. Back the file up (or note the last-known ID) before touching `STATE_DIR`.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-wire-up-the-deploy-relay-on-the-colo-server).*

## Caveats

### Is it safe to loosen the deploy relay's systemd hardening if a plugin needs to write outside `STATE_DIR`?

Don't loosen `ProtectSystem=strict` — add the specific path to `ReadWritePaths` instead. The hardening exists precisely so a compromised or misbehaving deploy step can't touch the rest of the filesystem; widening `ProtectSystem` defeats that for the sake of one write target.

### Does the local-model tunnel relax SSH host-key checking to make connecting easier?

No, and don't make it. It runs with `StrictHostKeyChecking=yes` and `BatchMode=yes` deliberately — no interactive prompts, no silent trust-on-first-use. The practical cost is that a missing `known_hosts` entry for the tunnel's IP (not the `SSH_HOST` alias) fails the connection silently rather than prompting; you have to pre-seed `known_hosts` yourself, which is the intended friction, not a bug.

## Trust

### Does `colo-sync` risk syncing secrets or credentials accidentally?

It excludes the usual noise (`node_modules`, `_build`, `.venv`, `.terraform`, `dist`) but has **no secret-aware filtering** — it will happily sync a `.env` or credentials file sitting in the synced tree just like any other file. Treat it as plain rsync for trust purposes: know what's under the path you're syncing before you run it.

### Does `colo-deploy-relay` open any inbound port on the colo server?

No — that's the entire point of the pull design. It only makes outbound calls (`gh api` to GitHub, `helm-upgrade` against the cluster it already has `kubectl` access to). There is nothing for an external actor to connect to on the relay side.
