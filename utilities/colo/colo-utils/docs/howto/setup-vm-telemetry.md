# How to: install telemetry on a new VM/EC2 host

**Goal:** stand up `signoz-otel-collector` + Fluent Bit on a non-Kubernetes host (VM/EC2/bare metal), auto-detecting local services (PostgreSQL, MySQL, Nginx, Redis, Docker) and shipping to a central OTLP endpoint.
**Prereqs:** root/sudo on the target host; run **on that host**, not your dev machine.

## Basic setup

```bash
cluster-setup-telemetry otel.example.com:4317
```

## With a custom hostname label

```bash
cluster-setup-telemetry 10.0.1.50:4317 legacy-db-01
```

## Force reinstall over an existing setup

```bash
FORCE_REINSTALL=1 cluster-setup-telemetry otel.example.com:4317
```

## Configure via infra-config.yaml

If `k8-lib` and an `infra-config.yaml` are present on the host, add:
```yaml
telemetry:
  environment: production       # deployment.environment resource attribute
  host_type: ec2                # host.type attribute (ec2 | vm | bare-metal)
  otelcol_version: "0.129.12"   # signoz-otel-collector release version
  resource_detectors: "env, system, ec2"
  otelcol_memory_limit_mib: 512
  otelcol_spike_limit_mib: 128
```
Every key is also overridable via `K8_TELEMETRY_*` env vars, and the tool falls back to built-in defaults when k8-lib/config isn't present at all — safe on bare remote VMs.

## Service-specific credentials (for auto-detected services)

| Variable | Purpose |
|----------|---------|
| `PG_MONITOR_USER` / `PG_MONITOR_PASSWORD` | PostgreSQL monitoring credentials |
| `MYSQL_MONITOR_USER` / `MYSQL_MONITOR_PASSWORD` | MySQL monitoring credentials |

**Verify:** `systemctl status signoz-otel-collector` and the Fluent Bit service are active; traces/logs appear at the configured OTLP endpoint within a minute.

**Gotchas:**
- Must run as root/sudo — it installs system services; running unprivileged fails partway through with permission errors.
- Re-running without `FORCE_REINSTALL=1` against an existing install is a no-op by design — set the flag to overwrite configs/binaries.
- Auto-detected services with no credentials set (e.g. `PG_MONITOR_USER` unset) are skipped from monitoring, not failed — check the install output for which integrations were actually enabled.
