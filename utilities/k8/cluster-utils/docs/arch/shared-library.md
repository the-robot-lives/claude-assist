# Shared Library — k8-lib

`cluster-utils` contains no library code of its own. All shared logic comes from the
repo-level **k8-lib** package (monorepo `share/k8-lib/`, installed to
`~/.local/share/k8-lib` by the parent repo's `make install-utilities`).

## Source Pattern

Every dashboard resolves the library by absolute path and sources three modules:

```bash
K8_LIB_DIR="${K8_LIB_DIR:-${HOME}/.local/share/k8-lib}"

# Pre-parse --config so K8_CONFIG is set before library init
#   --config=<path>  or  --config <path>  → export K8_CONFIG

source "$K8_LIB_DIR/bin/config.sh"
source "$K8_LIB_DIR/bin/common.sh"
source "$K8_LIB_DIR/bin/assist.sh"
_k8_check_assist "$0" "$@"
```

Because the path is absolute (not relative to the script), installed copies in
`~/.local/bin` work from anywhere. Override the library location with `K8_LIB_DIR`.

## Modules Used

| Module | Provides |
|--------|----------|
| `config.sh` | Settings read from `infra-config.yaml` via `config-resolver.sh` — tier groupings, status patterns, namespaces, Manticore S3 bucket/labels, `telemetry:` block. `${VAR:-default}` pattern throughout, so all values are env-overridable |
| `common.sh` | Color constants (`NC`, `RED`, `GRN`, `YEL`, `BOLD`, `DIM`, `CYAN`, `MAG`), status symbols (`PASS`/`FAIL`/`WARN`), column/separator formatting helpers |
| `assist.sh` | `--assist "question"` support on every tool — invokes Claude Code headlessly with tool context via `_k8_check_assist` |

## Config Precedence

1. `--config <path>` / `--config=<path>` CLI flag (pre-parsed into `K8_CONFIG` before sourcing)
2. `K8_CONFIG` env var
3. Default `infra-config.yaml` discovery by `config-resolver.sh`
4. Per-variable env overrides (e.g. `K8_MANTICORE_S3_BUCKET`, `K8_TELEMETRY_*`)

## Optional Dependency: cluster-setup-telemetry

`cluster-setup-telemetry` runs on remote VMs/EC2 hosts where k8-lib is typically absent.
It sources `config.sh` only if present and uses the `assist.sh` full-bootstrap pattern
(`[[ -f "$_K8_ASSIST_LIB" ]] && source ...`), falling back to built-in defaults with
`K8_TELEMETRY_*` env overrides otherwise.
