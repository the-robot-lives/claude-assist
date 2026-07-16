# Shared Library — k8-lib

`k8-lib` is the monorepo-wide shell library shared by all Noizu DevOps utilities. It is **external** to colo-utils: installed to `~/.local/share/k8-lib` by the parent repo's `make install-utilities`, with a sibling checkout at `../k8-lib` in the monorepo tree.

## Resolution

```bash
K8_LIB_DIR="${K8_LIB_DIR:-${HOME}/.local/share/k8-lib}"
source "$K8_LIB_DIR/bin/config.sh"
source "$K8_LIB_DIR/bin/common.sh"
source "$K8_LIB_DIR/bin/assist.sh"
_k8_check_assist "$0" "$@"
```

`colo-sync` additionally prefers the repo sibling when it exists:

```bash
_repo_k8_lib="$SCRIPT_DIR/../../k8-lib"
[[ -f "$_repo_k8_lib/bin/common.sh" ]] && K8_LIB_DIR="$(cd "$_repo_k8_lib" && pwd)"
```

## What Each File Provides

| File | Provides |
|------|----------|
| `bin/config.sh` | `infra-config.yaml` resolution: tier groupings, status patterns, `telemetry:` section, `K8_*` variables (all `${VAR:-default}` overridable) |
| `bin/common.sh` | Color constants (`NC`, `RED`, `GRN`, `YEL`, …), status symbols (`PASS`/`FAIL`/`WARN`), formatting helpers |
| `bin/assist.sh` | `_k8_check_assist` — the `--assist` flag hook for AI-powered help on any tool |

## `--config` Pre-parsing

`cluster-*` tools scan argv for `--config <path>` / `--config=<path>` **before** sourcing `config.sh` and export it as `K8_CONFIG`, so an alternate `infra-config.yaml` takes effect during library load.

## Graceful Degradation

Sourcing is conditional (`[[ -f … ]] && source …`) in the `colo-*` tools and `cluster-setup-telemetry` falls back to built-in defaults, so scripts run on hosts where k8-lib is not installed (remote VMs, the colo server).
