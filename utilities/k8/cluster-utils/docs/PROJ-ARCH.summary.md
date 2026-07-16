# cluster-utils — Architecture Summary

Terminal utility package of standalone Bash dashboards for Kubernetes cluster inspection.
Seven `cluster-*` scripts in `bin/` query kubectl, helm, and metrics-server against the
current kubectl context and render color-coded dashboards. No in-repo library: shared
config, formatting, and `--assist` AI help are sourced at runtime from the repo-level
k8-lib at `~/.local/share/k8-lib` (`K8_LIB_DIR` overridable). Config comes from the
repo-root `infra-config.yaml` (per-invocation override via `--config <path>`, pre-parsed
before library sourcing). Installed to `~/.local/bin` via `make install` or the monorepo's
`make install-utilities`.

## Components

- **cluster-status** — Tiered pod dashboard grouped by category; `--watch` auto-refresh
- **cluster-nodes** — Node layout with CPU/RAM reservations; `--pods` placement
- **cluster-resources** — Per-pod CPU/RAM usage vs requests (needs metrics-server)
- **cluster-helm** — Helm release status with failure highlighting
- **cluster-layout** — Node/pod/PVC/PV layout as markdown (rendered via glow)
- **cluster-manticore** — Manticore Search readers, index versions, S3 state, jobs
- **cluster-setup-telemetry** — OTel Collector + Fluent Bit installer for VMs/EC2 (remote host, root; k8-lib optional)
- **Makefile** — `make install` copies `bin/cluster-*` to `INSTALL_DIR` (default `~/.local/bin`)

## Key Decisions

- Standalone Bash, no compiled deps
- k8-lib sourced by absolute path — installed copies are path-independent
- `--config` pre-parsed before k8-lib init
- `cluster-setup-telemetry` degrades gracefully without k8-lib (`K8_TELEMETRY_*` env overrides)
