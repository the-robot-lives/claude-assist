# cluster-utils — How-To Task List

Companion index to [PROJ-HOWTO.md](PROJ-HOWTO.md) — task + one-line outcome only.

| Task | Outcome |
|------|---------|
| Install cluster-utils and verify it works | `cluster-*` commands on `PATH`, `cluster-status` reaches your cluster |
| Check overall cluster health | Tiered, color-coded pod dashboard (`cluster-status`, `--watch` for live) |
| Inspect node capacity and pod placement | Per-node CPU/RAM reservations, optional pod placement (`cluster-nodes [--pods]`) |
| Check per-pod resource usage vs requests | Pods exceeding their CPU/RAM requests flagged (`cluster-resources`, needs metrics-server) |
| Review Helm release health | Failed/pending releases highlighted (`cluster-helm`) |
| Generate a markdown snapshot of the cluster layout | Shareable/versionable markdown of node/pod/storage layout (`cluster-layout`) |
| Check Manticore Search cluster status | Reader, index, S3, and job status dashboard (`cluster-manticore`) |
| Get AI-assisted help from any tool | In-terminal AI answer using the tool's own output as context (`--assist "question"`) |
| Point a tool at a non-default config file | Dashboard runs against an alternate `infra-config.yaml` (`--config <path>`) |
| Install telemetry collection on a VM/EC2 host | OTel Collector + Fluent Bit shipping metrics/logs to a central endpoint (`cluster-setup-telemetry`) — [howto/setup-telemetry.md](howto/setup-telemetry.md) |
