# cluster-utils — FAQ Question Index

Companion index to [PROJ-FAQ.md](PROJ-FAQ.md) — question headings only, grouped by category.

## Motivation
- Why would I use `cluster-status`/`cluster-nodes`/etc. instead of raw `kubectl get pods -A`?
- Why does `--assist` exist instead of me just reading the dashboard output myself?
- Why doesn't `make install` in this package also install k8-lib, given every tool hard-requires it?
- Why is `cluster-setup-telemetry` in this package instead of just deploying an OTel Collector Helm chart in-cluster?

## Fit
- When is this the wrong tool for the job?
- Is this meant to replace `k9s` or Lens?

## Comparison
- How does `cluster-resources` differ from plain `kubectl top pods`?
- How does `cluster-layout`'s markdown output differ from `cluster-nodes --pods`?

## Capability
- Can these tools run without an `infra-config.yaml`?
- Can I change `cluster-status --watch`'s 5-second refresh interval?
- Can `cluster-manticore` tell me AWS creds are missing?

## Caveats
- What happens if I run these against the wrong `kubectl` context?
- Does `--assist` send my cluster output anywhere?
- Does `cluster-setup-telemetry` need root, and why?
- Does `--config` really have to come first on the command line, like the HOWTO gotcha implies?

## Trust
- Does anything here write back to my cluster or mutate state?
- Where do credentials for `cluster-manticore`/`cluster-setup-telemetry` come from, and are they stored by this tool?
