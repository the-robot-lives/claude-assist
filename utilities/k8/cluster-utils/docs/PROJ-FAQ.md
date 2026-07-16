# cluster-utils — FAQ

Anticipated why/when/compared-to-what questions. For *how to run something* see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for *what it is* see [PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use `cluster-status`/`cluster-nodes`/etc. instead of raw `kubectl get pods -A`?

The dashboards group and color-code output by deployment tier and health so a problem
jumps out in one glance instead of requiring you to scan a flat pod list. `cluster-status`
maps namespaces to tiers from `infra-config.yaml` and marks red/yellow/green; raw `kubectl`
gives you the same data but no grouping, no coloring, and no tier context. The trade-off:
these are read-only summaries, not a full TUI — for live filtering/sorting/exec-into-pod
you still want `k9s` or `kubectl` directly.
→ *See [PROJ-HOWTO.md#how-to-check-overall-cluster-health](PROJ-HOWTO.md#how-to-check-overall-cluster-health).*

### Why does `--assist` exist instead of me just reading the dashboard output myself?

It saves the round-trip of copy-pasting dashboard output into a chat session when you want
an interpretation, not just the raw numbers — e.g. "why is apps-ns red?" answered in the
same terminal. It's a convenience layer over the tool's own output, not a smarter data
source: the answer quality is bounded by what the dashboard already shows. Skip it for
routine checks; reach for it when you'd otherwise be pasting output elsewhere to reason
about it.
→ *See [PROJ-HOWTO.md#how-to-get-ai-assisted-help-from-any-tool](PROJ-HOWTO.md#how-to-get-ai-assisted-help-from-any-tool).*

### Why doesn't `make install` in this package also install k8-lib, given every tool hard-requires it?

Because k8-lib is shared across *all* Noizu k8 utilities packages, not just this one, and
bundling a copy here would mean N duplicate copies drifting out of sync across N packages.
`make install` in this directory only owns `bin/cluster-*`; k8-lib installation is the
monorepo's job (`make install-utilities` from the repo root), same as every sibling
`k8/*-utils` package. The trade-off is exactly the HOWTO gotcha you hit: installing this
package alone, in isolation, gets you binaries that error on first run until k8-lib exists
somewhere `K8_LIB_DIR` can find it.
→ *See [PROJ-HOWTO.md#how-to-install-cluster-utils-and-verify-it-works](PROJ-HOWTO.md#how-to-install-cluster-utils-and-verify-it-works).*

### Why is `cluster-setup-telemetry` in this package instead of just deploying an OTel Collector Helm chart in-cluster?

Because its target is hosts that *aren't* in the cluster — standalone VMs and EC2
instances running things like a legacy PostgreSQL box — where a Helm chart has nothing to
install into. It bootstraps the collector and Fluent Bit directly on the host and points
them at your central OTLP endpoint. If the host you're instrumenting already runs inside
the k8s cluster, you don't need this tool at all; use your normal in-cluster OTel
deployment.
→ *See [howto/setup-telemetry.md](howto/setup-telemetry.md).*

## Fit

### When is this the wrong tool for the job?

When you need historical trends, alerting, or multi-cluster aggregation — these dashboards
are point-in-time snapshots of whatever `kubectl` context is currently active, with no
storage or comparison across runs. Reach for Prometheus/Grafana (trends, alerting) or a
multi-context tool (fleet-wide views) instead; `cluster-status --watch` gives you a
live-refreshing single-cluster view, not a time series.

### Is this meant to replace `k9s` or Lens?

No. Those are interactive, general-purpose Kubernetes browsers (navigate, filter, exec,
edit); `cluster-utils` is a set of narrow, opinionated dashboards for specific recurring
checks (tiered health, node capacity, Helm status, Manticore state). Use `k9s`/Lens when
you need to *act* on the cluster interactively; use `cluster-utils` for a fast, scriptable
read of a specific concern.

## Comparison

### How does `cluster-resources` differ from plain `kubectl top pods`?

`cluster-resources` cross-references live usage against each pod's *requests* and flags
the ones exceeding them, which `kubectl top` alone doesn't compute for you — you'd have to
pull `kubectl describe`/requests separately and diff manually. Both need `metrics-server`;
if `kubectl top nodes` errors, `cluster-resources` will too.
→ *See [PROJ-HOWTO.md#how-to-check-per-pod-resource-usage-vs-requests](PROJ-HOWTO.md#how-to-check-per-pod-resource-usage-vs-requests).*

### How does `cluster-layout`'s markdown output differ from `cluster-nodes --pods`?

`cluster-nodes --pods` is a terminal-only summary for a quick look; `cluster-layout`
produces a full markdown document (node pools, pod placement, PVC→PV storage mapping)
meant to be saved or pasted into an incident writeup — it's the one dashboard designed for
output *other than* your terminal.
→ *See [PROJ-HOWTO.md#how-to-generate-a-markdown-snapshot-of-the-cluster-layout](PROJ-HOWTO.md#how-to-generate-a-markdown-snapshot-of-the-cluster-layout).*

## Capability

### Can these tools run without an `infra-config.yaml`?

Yes — every dashboard falls back to built-in defaults (tier groupings, node pool labels,
status patterns) if no config is found. You lose precision (pods land in generic groupings
instead of your tier scheme), not function. `cluster-setup-telemetry` goes further and
treats k8-lib itself as optional for the same reason: it may run on a remote VM where
neither exists.

### Can I change `cluster-status --watch`'s 5-second refresh interval?

No — the interval is hardcoded (`sleep 5` in the watch loop) with no flag or env var
override. If 5s is too fast/slow for your workflow, run one-shot `cluster-status` in your
own polling loop (e.g. `watch -n 15 cluster-status`) instead of the built-in `--watch`.
→ *See [PROJ-HOWTO.md#how-to-check-overall-cluster-health](PROJ-HOWTO.md#how-to-check-overall-cluster-health).*

### Can `cluster-manticore` tell me AWS creds are missing?

No — this is a sharp edge worth knowing before you rely on it. If AWS credentials can't
read the index bucket (`K8_MANTICORE_S3_BUCKET`, default `manticore-indexes`), the `aws s3`
calls fail silently and the S3/job sections of the dashboard just render empty rather than
erroring. An empty S3 section can mean "no indexes" or "no credentials" — check
`aws s3 ls s3://manticore-indexes` yourself if a section looks suspiciously blank.
→ *See [PROJ-HOWTO.md#how-to-check-manticore-search-cluster-status](PROJ-HOWTO.md#how-to-check-manticore-search-cluster-status).*

## Caveats

### What happens if I run these against the wrong `kubectl` context?

You get a dashboard for whatever cluster your current context points at, with no warning
that it might not be the one you meant — there's no cluster-name confirmation prompt.
Check `kubectl config current-context` before running anything destructive-adjacent (there
isn't any destructive action here, but a misread dashboard can still send you chasing the
wrong cluster's problem).

### Does `--assist` send my cluster output anywhere?

It invokes the Claude Code CLI headlessly on your machine, passing the dashboard's own
output as context for whatever question you ask — so yes, that output leaves your terminal
process and goes wherever your local `claude` CLI sends it (per your own Claude Code/API
configuration), same as any other `claude` invocation you'd run by hand. If your dashboard
output includes anything sensitive (node IPs, internal hostnames), treat `--assist` calls
like any other prompt you'd send through your configured Claude account. It fails
gracefully (`claude CLI not found`) rather than silently no-op'ing if the CLI isn't
installed.

### Does `cluster-setup-telemetry` need root, and why?

Yes, always — it installs and configures system-level services (OTel Collector, Fluent
Bit) on the target host, which requires root/sudo on any normal Linux install. It's meant
to run *on* the VM/EC2 host being instrumented, not on your dev machine. `FORCE_REINSTALL=1`
overwrites an existing install; omit it if you just want config changes to your existing
one applied idempotently. See the env var list in `howto/setup-telemetry.md` for
service-specific credentials it may prompt for (PostgreSQL/MySQL monitoring users).

### Does `--config` really have to come first on the command line, like the HOWTO gotcha implies?

No — despite the cautious phrasing, every tool pre-scans *all* of `$@` for `--config`
before sourcing k8-lib, so `cluster-nodes --pods --config <path>` and
`cluster-nodes --config <path> --pods` behave identically. The gotcha is defensive advice
(config resolution genuinely must happen before k8-lib is sourced, which is what actually
matters), not a documented positional requirement of the flag itself — put it wherever's
convenient.
→ *See [PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-file](PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-file).*

## Trust

### Does anything here write back to my cluster or mutate state?

No — every `cluster-*` dashboard is read-only (`kubectl get`, `kubectl top`, `helm list`,
`aws s3 ls`, and similar). The one tool that changes host state is
`cluster-setup-telemetry`, and only on the remote VM/EC2 host it's run on, not on the
Kubernetes cluster.

### Where do credentials for `cluster-manticore`/`cluster-setup-telemetry` come from, and are they stored by this tool?

They're read from your existing environment/AWS credential chain
(`K8_MANTICORE_S3_BUCKET`-scoped AWS creds, `PG_MONITOR_USER`/`PG_MONITOR_PASSWORD`,
`MYSQL_MONITOR_USER`/`MYSQL_MONITOR_PASSWORD`) — this package doesn't generate, store, or
transmit credentials of its own; it only consumes whatever's already in your shell/host
environment when it shells out to `aws`/config templates.
