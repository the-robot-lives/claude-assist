# Installation

## Makefile

| Target | Purpose |
|--------|---------|
| `compile` | No-op (pure Bash) |
| `test` | No-op (placeholder) |
| `install` | Copies `bin/colo-*` to `INSTALL_DIR` with mode 755 |
| `local-model-link-on/off/status/logs` | Wraps `bin/colo-local-model-link` lifecycle commands |

Default `INSTALL_DIR` is `~/.local/bin`; override with `make install INSTALL_DIR=/usr/local/bin`.

## Split Install Responsibility

- **`colo-*` scripts** — installed here by `make install`.
- **`cluster-*` scripts** — installed by the parent monorepo's `make install-utilities`, which also installs the shared `k8-lib` to `~/.local/share/k8-lib`. They can also run directly from `bin/`.
- **`colo-deploy-relay.service` / `.timer`** — copied manually to the colo server (`/etc/systemd/system/`), adjust `DEPLOY_REPO`/`DEPLOY_ENV` in the unit, then enable the timer. Not part of local install.
- **`colo-local-model-link`** — self-installing: `colo-local-model-link on` writes and loads a macOS LaunchDaemon plist (requires sudo; macOS only).

## Library Dependency

Scripts resolve k8-lib via `$K8_LIB_DIR` (default `~/.local/share/k8-lib`) rather than a path relative to the script, so installed copies work anywhere. Sourcing is guarded — missing k8-lib means defaults instead of failures (e.g. `cluster-setup-telemetry` on a remote VM).

## Prerequisites

- `kubectl` with cluster access (current context is used); `helm` for release inspection
- `glow` optional, for `cluster-layout` markdown rendering
- Colo server relay: `gh` CLI authenticated with a deployments-capable PAT, plus `helm-upgrade` on PATH (from k8-lib devops tools)
