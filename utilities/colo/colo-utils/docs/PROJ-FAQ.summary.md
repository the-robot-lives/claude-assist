# colo-utils — FAQ Index

Question headings only, grouped by category. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use `colo-sync` instead of just running `rsync` myself?
- Why does `colo-deploy-relay` poll GitHub instead of receiving a webhook?
- Why is the local-model tunnel a LaunchDaemon instead of a terminal `ssh -R` I run by hand?
- Why does `make install` in this directory only install `colo-*` tools, not `cluster-*`?

## Fit
- When should I reach for `cluster-status`/`cluster-nodes`/etc. instead of raw `kubectl get pods`?
- Is `colo-local-model-link` any use if I'm not on macOS?
- Should I run `cluster-setup-telemetry` on my own dev machine?

## Comparison
- How does `colo-utils` differ from `k8-lib`?
- How does `cluster-nodes` differ from `cluster-resources` — don't they both show usage?
- How is `colo-deploy-relay` different from a normal CI/CD push-based deploy?

## Capability
- Can `colo-sync`/`cluster-*` run without `k8-lib` installed?
- Can `colo-deploy-relay` recover if I delete its state file?

## Caveats
- Is it safe to loosen the deploy relay's systemd hardening if a plugin needs to write outside `STATE_DIR`?
- Does the local-model tunnel relax SSH host-key checking to make connecting easier?

## Trust
- Does `colo-sync` risk syncing secrets or credentials accidentally?
- Does `colo-deploy-relay` open any inbound port on the colo server?
