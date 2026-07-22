# colo-utils — How-To Summary

Task list only. Full steps in [PROJ-HOWTO.md](PROJ-HOWTO.md) and `howto/`.

- **Install the tools** — get `cluster-*` and `colo-*` commands on your `PATH`.
- **Check overall cluster pod health** — see every pod's status, grouped by deployment tier, with problems highlighted red/yellow.
- **Inspect node capacity and placement** — see CPU/RAM reservations per node, and optionally which pods sit where.
- **Check pod resource usage vs requests** — spot pods using far more (or less) than they requested.
- **Check Helm release health** — see every Helm release's status at a glance, failures highlighted.
- **View full cluster storage/node layout** — a single rendered-markdown view of nodes, PVCs, and PVs.
- **Check Manticore Search cluster state** — dashboard of Manticore readers, indexes, S3 backend state, and running jobs.
- **Sync files with the colo server** — push or pull files between your machine and `noizu.server` with automatic `/Users` ↔ `/home` path mirroring. → [howto/sync-with-colo-server.md](howto/sync-with-colo-server.md)
- **Keep an SSH tunnel open to the colo local-model port** — a persistent, auto-restarting reverse tunnel from `noizu.server:3713` to your Mac, managed as a LaunchDaemon. → [howto/local-model-tunnel.md](howto/local-model-tunnel.md)
- **Install telemetry on a new VM/EC2 host** — stand up OTel Collector + Fluent Bit on a non-cluster host, auto-detecting local services and pointing at a central OTLP endpoint. → [howto/setup-vm-telemetry.md](howto/setup-vm-telemetry.md)
- **Wire up the deploy relay on the colo server** — have the colo server pull GitHub Deployments every 60s and run `helm-upgrade` automatically, with no inbound webhook needed. → [howto/deploy-relay-setup.md](howto/deploy-relay-setup.md)
