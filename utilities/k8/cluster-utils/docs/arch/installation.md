# Installation

## Makefile

The `Makefile` provides three targets:

| Target | Purpose |
|--------|---------|
| `compile` | No-op (pure Bash, nothing to compile) |
| `test` | No-op (placeholder for future tests) |
| `install` | Copies `bin/cluster-*` to `INSTALL_DIR` with mode 755 |

## Install Directory

Default: `~/.local/bin`. Override with:

```bash
make install INSTALL_DIR=/usr/local/bin
```

## Library Dependency

Installed scripts source k8-lib by **absolute path** —
`${K8_LIB_DIR:-$HOME/.local/share/k8-lib}` — not relative to the script location, so
copies in `~/.local/bin` (or anywhere else) work without a co-located `share/` tree.

k8-lib itself is installed by the parent monorepo:

```bash
make install-utilities   # from the Noizu monorepo root — installs all utilities + k8-lib
```

If k8-lib lives elsewhere, set `K8_LIB_DIR` before invoking any tool.
`cluster-setup-telemetry` is the exception: it tolerates a missing k8-lib entirely (it
runs on remote VMs) and falls back to defaults plus `K8_TELEMETRY_*` env overrides.
