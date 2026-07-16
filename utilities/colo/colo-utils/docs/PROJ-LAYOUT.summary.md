# Project Layout — Summary

```
colo-utils/
├── bin/                            # Bash utilities
│   ├── cluster-status              # Tiered pod dashboard
│   ├── cluster-nodes               # Node capacity/reservations
│   ├── cluster-resources           # Pod usage vs requests
│   ├── cluster-helm                # Helm release status
│   ├── cluster-layout              # Node/PVC/PV markdown layout
│   ├── cluster-manticore           # Manticore search dashboard
│   ├── cluster-setup-telemetry     # OTel + Fluent Bit VM installer
│   ├── colo-deploy-relay           # GitHub deployments → helm-upgrade relay
│   ├── colo-local-model-link       # macOS SSH tunnel LaunchDaemon
│   └── colo-sync                   # rsync local ↔ colo server
├── docs/                           # PROJ-ARCH, PROJ-LAYOUT + arch/ details
│   └── arch/                       # installation.md, shared-library.md
├── colo-deploy-relay.service       # systemd oneshot unit (colo server)
├── colo-deploy-relay.timer         # 60s polling timer
├── .gitignore
├── Makefile                        # install colo-* tools; local-model-link targets
└── README.md                       # Tool reference and usage
```
