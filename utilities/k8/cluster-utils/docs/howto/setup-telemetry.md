# How to: install telemetry collection on a VM/EC2 host

**Goal:** Get an OTel Collector + Fluent Bit shipping metrics/logs from a non-Kubernetes
host (a VM or EC2 instance) to a central OTLP endpoint, with auto-detected scraping for
PostgreSQL, MySQL, Nginx, Redis, and Docker.
**Prereqs:** Root/sudo on the **target host** (not your dev machine — this installs system
services there). A reachable central OTel Collector endpoint (host:port for gRPC/OTLP).

1. Copy or check out `cluster-setup-telemetry` onto the target host (it tolerates a missing
   `k8-lib`, so no other install step is required there).
2. Run it with the OTLP endpoint of your central collector:
   ```bash
   sudo cluster-setup-telemetry otel.example.com:4317
   ```
3. Optionally pass a custom hostname label (defaults to the host's own hostname):
   ```bash
   sudo cluster-setup-telemetry 10.0.1.50:4317 legacy-db-01
   ```
4. Re-running on a host that already has the collector installed prompts before
   overwriting; skip the prompt non-interactively with:
   ```bash
   FORCE_REINSTALL=1 sudo cluster-setup-telemetry otel.example.com:4317
   ```

**Verify:**
```bash
systemctl status signoz-otel-collector fluent-bit
```
Both should be `active (running)`. Config lands at `/etc/signoz-otel-collector/config.yaml`
and `/etc/fluent-bit/fluent-bit.conf`.

**Config precedence** (in `infra-config.yaml` under `telemetry:`, all overridable by
`K8_TELEMETRY_*` env vars):

```yaml
telemetry:
  environment: production       # deployment.environment resource attribute
  host_type: ec2                # host.type attribute (ec2 | vm | bare-metal)
  otelcol_version: "0.129.12"   # signoz-otel-collector release version
  resource_detectors: "env, system, ec2"
  otelcol_memory_limit_mib: 512
  otelcol_spike_limit_mib: 128
```

**Monitoring specific services:** set credentials before running so the auto-detected
scrapers can authenticate:

| Variable | Purpose |
|----------|---------|
| `PG_MONITOR_USER` / `PG_MONITOR_PASSWORD` | PostgreSQL monitoring credentials |
| `PG_MONITOR_HOST` / `PG_MONITOR_PORT` | Default `localhost:5432` |
| `MYSQL_MONITOR_USER` / `MYSQL_MONITOR_PASSWORD` | MySQL monitoring credentials |
| `MYSQL_MONITOR_HOST` / `MYSQL_MONITOR_PORT` | Default `localhost:3306` |

**Gotchas:**
- Must run as root — it installs system-level binaries and systemd units.
- Runs on the **target host itself**, not against a remote host over SSH — copy the script
  there first.
- If `infra-config.yaml`/`k8-lib` aren't present on the host, everything still works via
  built-in defaults — this is the one tool designed for that case.
- No endpoint argument prints usage and exits 1 rather than doing anything.
