# Project Layout

Terminal utility package: Kubernetes cluster inspection dashboards (`cluster-*`) plus colo-server helpers (`colo-*`) for the noizu colo host. Scripts share configuration/formatting via the external `k8-lib` shell library (`~/.local/share/k8-lib`, sibling `../k8-lib`). Installed to `~/.local/bin` via `make install`.

```
colo-utils/
├── bin/                            # Executable Bash utilities (installed to ~/.local/bin)
│   ├── cluster-status              #   Tiered pod dashboard across namespaces (--watch)
│   ├── cluster-nodes               #   Node layout: capacity type, CPU/RAM reservations (--pods)
│   ├── cluster-resources           #   Per-pod CPU/RAM usage vs requests (needs metrics-server)
│   ├── cluster-helm                #   Helm release status, color-coded by health
│   ├── cluster-layout              #   Node/PVC/PV layout as rendered markdown (glow optional)
│   ├── cluster-manticore           #   Manticore search dashboard (readers, indexes, S3, jobs)
│   ├── cluster-setup-telemetry     #   Install OTel Collector + Fluent Bit on a VM/EC2 host
│   ├── colo-deploy-relay           #   Polls GitHub Deployments API, runs helm-upgrade (systemd timer)
│   ├── colo-local-model-link       #   macOS LaunchDaemon: SSH tunnel to colo local-model port
│   └── colo-sync                   #   rsync local ↔ noizu.server with mirrored path mapping
├── docs/                           # Documentation
│   ├── PROJ-ARCH.md                #   Architecture: components, data flow, diagrams
│   ├── PROJ-ARCH.summary.md        #   Architecture quick reference
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Layout quick reference (keep in sync)
│   └── arch/                       #   Architecture detail docs
│       ├── installation.md         #     Install flow and prerequisites
│       └── shared-library.md       #     k8-lib sourcing and config resolution
├── colo-deploy-relay.service       # systemd oneshot unit for the deploy relay (hardened, User=deploy)
├── colo-deploy-relay.timer         # systemd timer — polls every 60s (30s after boot)
├── .gitignore                      # Ignores .env, .envrc.local, editor swap files
├── Makefile                        # install (colo-* → ~/.local/bin) + local-model-link on/off/status/logs
└── README.md                       # Tool reference, usage, telemetry configuration
```

## Notes

- **Only `colo-*` scripts are installed** by `make install`; `cluster-*` scripts run from `bin/` or are installed by the parent repo's `make install-utilities`.
- All `cluster-*` tools accept `--config <path>` and read `infra-config.yaml` (tier groupings, status patterns, `telemetry:` section) when present; they fall back to defaults without k8-lib.
- `colo-deploy-relay.service`/`.timer` are deployed to the colo server (not run locally); relay state lives in `/var/lib/deploy-relay`.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `kubectl` context | `cluster-*` tools use the current context |
| `~/.local/share/k8-lib` | Install via parent repo `make install-utilities` (optional; graceful fallback) |
| `colo-deploy-relay.service` | Copy to colo server, adjust `DEPLOY_REPO`/`DEPLOY_ENV`, enable timer |
