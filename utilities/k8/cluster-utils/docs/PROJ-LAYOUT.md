# Project Layout

`cluster-utils` is a terminal utility package of Kubernetes cluster inspection dashboards
(`cluster-*` commands) installed to `~/.local/bin` via `make install`. Bash scripts use
the current `kubectl` context and optionally read `infra-config.yaml` (via the shared
`k8-lib` library, see [PROJ-ARCH.md](PROJ-ARCH.md)) for tier groupings and status patterns.

```
cluster-utils/
├── bin/                            # Executable bash tools (installed as-is to ~/.local/bin)
│   ├── cluster-status              #   Tiered pod dashboard grouped by category; --watch auto-refresh
│   ├── cluster-nodes               #   Node layout: capacity type, CPU/RAM reservations; --pods placement
│   ├── cluster-resources           #   Per-pod CPU/RAM usage vs requests (requires metrics-server)
│   ├── cluster-helm                #   Helm release status with failure highlighting
│   ├── cluster-layout              #   Node/pod/PVC/PV layout as rendered markdown (uses glow)
│   ├── cluster-manticore           #   Manticore search dashboard: readers, index versions, S3, jobs
│   └── cluster-setup-telemetry     #   Install OTel Collector + Fluent Bit on a VM/EC2 (run on target host)
├── docs/                           # Documentation
│   ├── PROJ-ARCH.md                #   Architecture overview
│   ├── PROJ-ARCH.summary.md        #   Architecture summary (companion)
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Layout summary (companion)
│   └── arch/                       #   Detailed architecture notes
│       ├── installation.md         #     Install flow details
│       └── shared-library.md       #     k8-lib shared shell library usage
├── .gitignore                      # Ignores .env, .envrc.local, editor swap files
├── Makefile                        # `make install` → copies bin/cluster-* to ~/.local/bin (INSTALL_DIR overridable)
└── README.md                       # Start here — tool table, prerequisites, telemetry setup config
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `infra-config.yaml` (repo root, optional) | Provides tier groupings, status patterns, and `telemetry:` settings; every tool accepts `--config <path>` |
| `~/.local/share/k8-lib/` | Shared shell library installed by the parent repo's `make install-utilities`; optional for `cluster-setup-telemetry` |

## Notes

- No `lib/` folder — shared logic lives in the repo-level `k8-lib` package, sourced at runtime.
- `cluster-setup-telemetry` is the only tool run on remote hosts (requires root/sudo); all values overridable via `K8_TELEMETRY_*` env vars.
