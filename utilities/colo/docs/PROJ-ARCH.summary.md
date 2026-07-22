# Architecture Summary — utilities/colo

Grouping directory in the Noizu Infra monorepo's `utilities/` tree for colo-server-related utility packages. No runtime code of its own — a delegating Makefile (`SUBDIRS := colo-utils` via shared `utilities/mk/subdirs.mk`) fans build/install targets out to child packages, each self-documented under its own `docs/`.

## Components

- **Makefile** — subdir delegator; add new colo packages by appending to `SUBDIRS`
- **colo-utils/** — Bash tool families: `cluster-*` dashboards (kubectl/helm/metrics-server terminal views of the noizu k8s cluster) and `colo-*` helpers (GitHub-deployments pull relay + systemd units, macOS SSH tunnel LaunchDaemon, mirrored rsync). See `colo-utils/docs/PROJ-ARCH.summary.md`.

## Ecosystem Fit

Monorepo root `make install-utilities` installs `cluster-*` tools and shared `k8-lib` to `~/.local/bin` / `~/.local/share/k8-lib`; child `make install` covers only `colo-*` tools. Child tools source k8-lib guardedly and degrade without it. `colo-deploy-relay` keeps colo deploys pull-based via the repo's `helm-upgrade` utility.

## Key Decisions

Grouping directory rather than a package — children stay independently documented/installable with one monorepo fan-out point; architecture detail lives in child docs, not here.
