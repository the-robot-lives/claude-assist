# colo-utils — Architecture Summary

Terminal utility package with two Bash tool families: `cluster-*` dashboards that query kubectl/helm/metrics-server to render color-coded terminal views of the noizu k8s cluster, and `colo-*` helpers for the noizu colo server (deploy relay, SSH tunnel LaunchDaemon, mirrored rsync). Tools optionally source the shared `k8-lib` library from `~/.local/share/k8-lib` (config resolution, formatting, `--assist` hook) and degrade gracefully without it.

## Components

- **cluster-status / nodes / resources / helm / layout / manticore** — k8s inspection dashboards (pods by tier, node capacity, usage vs requests, Helm health, storage layout, Manticore state)
- **cluster-setup-telemetry** — installs OTel Collector + Fluent Bit on a VM/EC2 host
- **colo-deploy-relay** (+ systemd service/timer) — polls GitHub Deployments API every 60s on the colo server, runs `helm-upgrade`, reports status back; state in /var/lib/deploy-relay
- **colo-local-model-link** — macOS LaunchDaemon maintaining an SSH tunnel to the colo local-model port (3713)
- **colo-sync** — rsync local ↔ noizu.server with /Users ↔ /home path mapping

## Install

`make install` installs only `colo-*` to `~/.local/bin`; `cluster-*` and k8-lib come from the parent monorepo's `make install-utilities`. Systemd units are deployed to the colo server manually.

## Key Decisions

Standalone Bash with guarded k8-lib sourcing; pull-based deploys (no inbound webhook); env-var overridable defaults everywhere; ANSI/markdown output for at-a-glance health.
