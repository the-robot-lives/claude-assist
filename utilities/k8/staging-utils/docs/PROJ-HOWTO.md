# PROJ-HOWTO — staging-utils

Task-oriented guides for the `staging-*` tools. For what these tools are, see [PROJ-ARCH.md](PROJ-ARCH.md); for where files live, see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## Index

- [How to: install the staging tools](#how-to-install-the-staging-tools)
- [How to: deploy the staging environment](#how-to-deploy-the-staging-environment)
- [How to: tear down staging](#how-to-tear-down-staging)
- [How to: tail logs for a staging service](#how-to-tail-logs-for-a-staging-service)
- [How to: check staging status](#how-to-check-staging-status)
- [How to: wake up a KEDA-scaled-to-zero service](#how-to-wake-up-a-keda-scaled-to-zero-service)
- [How to: point a tool at a non-default config or namespace](#how-to-point-a-tool-at-a-non-default-config-or-namespace)
- [How to: get AI-assisted help from any staging-* command](#how-to-get-ai-assisted-help-from-any-staging--command)

---

## How to: install the staging tools

**Goal:** Get `staging-up`, `staging-down`, `staging-logs`, `staging-status` on your `PATH`.
**Prereqs:** `k8-lib` present at `~/.local/share/k8-lib` (installed by repo-root `make install-utilities`), `~/.local/bin` on `PATH`.

1. From this directory:
   ```bash
   make install
   ```
2. Or from the monorepo root, install everything at once:
   ```bash
   make install-utilities
   ```

**Verify:**
```bash
command -v staging-up staging-down staging-logs staging-status
```
**Gotchas:**
- Nothing is installed if `~/.local/bin` isn't on `PATH` — add it to your shell profile.
- `make install` only copies `bin/staging-*`; it does not install `k8-lib` or `helm-upgrade`. Run `make install-utilities` from repo root first if those are missing.

---

## How to: deploy the staging environment

**Goal:** Push the current Helm chart values to the staging namespace.
**Prereqs:** `helm-upgrade` (from `helm-tools`) on `PATH`; `kubectl`/`helm` cluster access; `.infra-config.yaml` reachable via the standard k8-lib config chain.

1. Run:
   ```bash
   staging-up
   ```
   This is a thin shim: `exec helm-upgrade --env stage --force "$@"` — any extra args you pass go straight to `helm-upgrade` (e.g. `--include <release>`, `--dry-run`).
2. Preview first if unsure:
   ```bash
   staging-up --dry-run
   ```

**Verify:**
```bash
staging-status
```
**Gotchas:**
- `staging-up` has no logic of its own beyond `--env stage --force` — flag errors are `helm-upgrade`'s; check `helm-upgrade --help` for accepted flags.
- `--force` is always passed, so a staging deploy will proceed even over drifted state — use `--dry-run` if you want a look first.

---

## How to: tear down staging

**Goal:** Remove every Helm release currently installed in the staging namespace.
**Prereqs:** Cluster access; nothing you need in staging still running.

1. Run:
   ```bash
   staging-down
   ```
   This uninstalls (`helm uninstall --wait`) every release `helm list -n <staging-ns> -q` returns, one at a time.

**Verify:**
```bash
helm list -n staging   # or your configured staging namespace
```
Should be empty.

**Gotchas:**
- No confirmation prompt — it uninstalls everything in the namespace unconditionally. Double-check `K8_STAGING_NAMESPACE`/config before running against a shared namespace.
- If a release hangs mid-uninstall (`--wait`), the script blocks until Helm's own timeout; Ctrl-C to abort, then investigate with `helm status <release> -n staging`.

---

## How to: tail logs for a staging service

**Goal:** Stream live logs for a specific staging deployment.
**Prereqs:** Service already deployed (see above); pods running (KEDA may have scaled to zero — see below).

1. Default (frontend):
   ```bash
   staging-logs
   ```
2. Named service:
   ```bash
   staging-logs backend
   staging-logs worker
   ```
   Any non-flag first argument is used verbatim as `<service>` in the label selector `app.kubernetes.io/name=<app_prefix>-<service>` — it doesn't have to be `frontend`/`backend`.
3. Pass through extra `kubectl logs` flags after the service name:
   ```bash
   staging-logs backend --since=10m
   ```

**Verify:** Log lines stream to your terminal (`kubectl logs --follow --all-containers`).
**Gotchas:**
- If it prints `No pods running for <service>` instead of streaming, KEDA has likely scaled to zero — see [How to: wake up a KEDA-scaled-to-zero service](#how-to-wake-up-a-keda-scaled-to-zero-service).
- The service name maps directly to a label value; a typo (e.g. `fronted`) silently returns "no pods" rather than an error — verify the deployment's actual `app.kubernetes.io/name` label with `staging-status` if unsure.

---

## How to: check staging status

**Goal:** See Helm releases, pod state, KEDA ScaledObjects, and resource usage for staging in one view.
**Prereqs:** Cluster access; `kubectl top` requires metrics-server installed for the resource-usage section.

1. Run:
   ```bash
   staging-status
   ```

**Verify:** Output shows four sections: `Helm Releases`, `Pods`, `ScaledObjects`, `Resource Usage`.
**Gotchas:**
- `(metrics unavailable)` under Resource Usage just means metrics-server isn't installed/reachable — not an error in this tool.
- `(no ScaledObjects — KEDA may not be installed)` is expected if the staging namespace has no autoscaled services.

---

## How to: wake up a KEDA-scaled-to-zero service

**Goal:** Bring a service back from zero replicas so logs/requests work again.
**Prereqs:** Service deployed with a KEDA `ScaledObject`; know its public staging URL.

1. Confirm it's actually scaled to zero:
   ```bash
   staging-status
   ```
   Look under `=== ScaledObjects ===` and `=== Pods ===`.
2. Wake it by sending traffic:
   ```bash
   curl https://<your-staging-url>
   ```
3. Re-check:
   ```bash
   staging-logs <service>
   ```

**Verify:** `staging-logs <service>` starts streaming instead of reporting no pods.
**Gotchas:** There's no CLI command in this package to force-scale — KEDA only reacts to actual traffic/metrics, so a `curl` (or hitting the app in a browser) is the documented way to trigger scale-up.

---

## How to: point a tool at a non-default config or namespace

**Goal:** Run any `staging-*` command against a different `.infra-config.yaml` or override the staging namespace/app-prefix without editing config files.
**Prereqs:** None beyond the tool itself.

1. Point at an alternate config file (accepted by every tool except `staging-up`, which forwards it to `helm-upgrade` instead):
   ```bash
   staging-status --config /path/to/other-infra-config.yaml
   ```
2. Or override individual values via env vars, no `--config` needed:
   ```bash
   K8_STAGING_NAMESPACE=staging-2 K8_APP_PREFIX=app2 staging-status
   ```

**Verify:** The section headers in `staging-status`/`staging-logs` output reflect the overridden namespace.
**Gotchas:**
- `--config` must be resolved before k8-lib is sourced — the scripts pre-parse it for this reason, so `staging-down --config foo.yaml` works, but don't expect config-dependent behavior from flags placed oddly; put `--config <path>` as its own token (or `--config=<path>`), not glued to other flags.
- `staging-up` has no local config parsing of its own — any `--config`/env override there is entirely `helm-upgrade`'s to interpret.

---

## How to: get AI-assisted help from any staging-* command

**Goal:** Ask a question about a tool's own usage without leaving the terminal.
**Prereqs:** `claude` CLI installed and on `PATH`.

1. Run:
   ```bash
   staging-logs --assist "why is this showing no pods for backend?"
   ```
   Works identically on `staging-up`, `staging-down`, `staging-status`, and `staging-logs`.

**Verify:** Claude Code responds inline using the script's own header comment as context.
**Gotchas:**
- Fails fast with an install pointer if `claude` isn't on `PATH`: `Error: claude CLI not found...`.
- `--assist` intercepts execution — the underlying command does not run; it's help-only, not "run and explain."
