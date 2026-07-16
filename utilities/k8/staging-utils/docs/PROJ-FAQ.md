# PROJ-FAQ — staging-utils

Why-would-I, when-shouldn't-I, and what's-the-catch questions for the `staging-*` tools. For procedures, see [PROJ-HOWTO.md](PROJ-HOWTO.md); for design rationale, see [PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use `staging-up`/`staging-down` instead of just running `helm`/`kubectl` directly?

Because they encode the staging-specific conventions (namespace, label prefix, `--force`) so you don't have to remember or retype them every time. `staging-up` is genuinely nothing more than `exec helm-upgrade --env stage --force "$@"` — you lose zero `helm-upgrade` functionality and gain the right flags applied consistently. `staging-down` saves you from hand-writing the `helm list -n <ns> -q | xargs helm uninstall` loop, and gets the namespace/app-prefix right from shared config instead of a value you typed from memory. The trade-off: they're conventions, not capability — if you need something `helm-upgrade` or raw `helm`/`kubectl` doesn't expose, these wrappers won't add it either.

→ *See [PROJ-HOWTO.md#how-to-deploy-the-staging-environment](PROJ-HOWTO.md#how-to-deploy-the-staging-environment).*

### Why does `staging-up` always pass `--force`?

Because staging is meant to be redeployed freely, including when Helm sees no chart diff — `--force` guarantees the deploy actually applies rather than silently no-op'ing on drifted state. The honest trade-off is that this removes one of Helm's own safety nets: a staging deploy will proceed even when something in the cluster has drifted out-of-band. Use `staging-up --dry-run` first if you want to see what would change before committing.

→ *See [PROJ-HOWTO.md#how-to-deploy-the-staging-environment](PROJ-HOWTO.md#how-to-deploy-the-staging-environment).*

### Why is there no `lib/` in this package — why depend on an external `k8-lib`?

So config resolution, `--config` handling, and `--assist` behave identically across every Noizu utility package, not just this one. Shared logic lives once in `k8-lib` (`~/.local/share/k8-lib`) and every `staging-*` script sources it at runtime; a fix or convention change there propagates everywhere without touching this package. The cost: these scripts don't run standalone — if `k8-lib` isn't installed (`make install-utilities` at repo root), sourcing fails and nothing here works.

→ *See [PROJ-ARCH.md#configuration-chain](PROJ-ARCH.md#configuration-chain).*

### Why would I use `staging-status` instead of running `kubectl get pods`/`helm list`/`kubectl get scaledobjects` separately?

Because it's the same three-to-four lookups run and formatted together, against the same resolved namespace every other `staging-*` tool uses, so you don't retype namespace flags or stitch outputs by hand. `staging-status` adds nothing `kubectl`/`helm` don't already expose — it's a convenience aggregation, not new data. The trade-off is the same as any wrapper: if you need output in a different shape (machine-readable JSON, a single resource type), reach for the underlying `kubectl`/`helm` commands directly instead.

→ *See [PROJ-HOWTO.md#how-to-check-staging-status](PROJ-HOWTO.md#how-to-check-staging-status).*

## Fit

### Why doesn't `staging-up` accept `--config` the way the other tools do?

Because `staging-up` isn't its own tool logically — it's a thin `exec` shim into `helm-upgrade`, so config resolution is entirely `helm-upgrade`'s responsibility, not something `staging-up` re-implements. Any `--config`/env override you pass gets forwarded as-is and interpreted by `helm-upgrade`, not pre-parsed the way `staging-down`/`staging-status`/`staging-logs` pre-parse it for their own namespace resolution. The practical effect: config behavior for deploys is documented under `helm-upgrade --help`, not this package.

→ *See [PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-or-namespace](PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-or-namespace).*

### When is `staging-utils` the wrong tool to reach for?

When you're targeting anything other than the staging namespace, or when you need finer-grained control than "all or nothing." `staging-down` uninstalls *every* release in the namespace with no per-release selection, and `staging-up` only ever deploys with `--env stage --force` baked in — neither is built for production, for a single-release deploy/rollback, or for a workflow that needs a confirmation gate. Reach for `helm-upgrade`/`helm`/`kubectl` directly once you need behavior these thin wrappers don't expose.

→ *See [PROJ-HOWTO.md#how-to-tear-down-staging](PROJ-HOWTO.md#how-to-tear-down-staging).*

### Can I point these tools at a namespace other than the default `staging`?

Yes — override `.kubernetes.staging_namespace` in an alternate config file (`--config <path>`) or set `K8_STAGING_NAMESPACE` directly; every tool except `staging-up` reads it. This is the intended way to run a second staging-like environment (e.g. `staging-2`) side by side. It does not, however, make these tools "environment-agnostic" beyond that one variable — `staging-up` still hardcodes `--env stage` when calling `helm-upgrade`, so a differently-named Helm environment isn't reachable through this shim.

→ *See [PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-or-namespace](PROJ-HOWTO.md#how-to-point-a-tool-at-a-non-default-config-or-namespace).*

## Comparison

### How does `staging-down` differ from running `helm uninstall --all -n staging` myself?

It's the same underlying operation, discovered dynamically instead of hardcoded: `staging-down` runs `helm list -n <resolved-namespace> -q` and uninstalls (`--wait`) each release it finds, using the namespace resolved from shared config rather than one you typed. The difference that matters: no `--all` flag exists to accidentally omit, and the namespace comes from the same config chain every other `staging-*` tool uses, so it can't silently diverge from what `staging-status` shows you.

→ *See [PROJ-ARCH.md#core-components](PROJ-ARCH.md#core-components).*

### How does `staging-up` differ from calling `helm-upgrade --env stage --force` directly?

It doesn't, functionally — `staging-up` is an 8-line shim around exactly that call, forwarding all extra arguments untouched. The only reason to prefer `staging-up` is muscle memory and not having to remember the two flags; anything `helm-upgrade --help` documents (`--include`, `--dry-run`, etc.) works identically through either path.

→ *See [PROJ-HOWTO.md#how-to-deploy-the-staging-environment](PROJ-HOWTO.md#how-to-deploy-the-staging-environment).*

## Capability

### Can `staging-logs` tail more than one service at once?

No — it takes exactly one service name (default `frontend`) and streams `kubectl logs --follow --all-containers` for pods matching that single label value. To watch multiple services, run separate `staging-logs <service>` invocations in separate terminals/panes; there's no built-in multiplexed view.

→ *See [PROJ-HOWTO.md#how-to-tail-logs-for-a-staging-service](PROJ-HOWTO.md#how-to-tail-logs-for-a-staging-service).*

### Can `staging-down` uninstall just one release instead of everything?

No — it always iterates every release Helm lists in the staging namespace; there's no flag to exclude or select a subset. If you need to remove a single release, use `helm uninstall <release> -n <namespace>` directly instead of this tool.

→ *See [PROJ-HOWTO.md#how-to-tear-down-staging](PROJ-HOWTO.md#how-to-tear-down-staging).*

### Can I preview what `staging-down` will remove before it actually deletes anything?

Not through the tool itself — there's no `--dry-run` flag; the documented safeguard is to run `helm list -n <namespace>` (or `staging-status`) beforehand and read that as your preview, since it's exactly the release set `staging-down` is about to iterate. This is a deliberate simplicity trade-off, not an oversight: adding a dry-run mode would mean duplicating Helm's own listing logic inside this script. Treat the pre-check as mandatory in shared namespaces.

→ *See [PROJ-HOWTO.md#how-to-tear-down-staging](PROJ-HOWTO.md#how-to-tear-down-staging).*

### Can I force a KEDA-scaled-to-zero service to wake up without sending it real traffic?

No — none of these tools expose a force-scale command; KEDA only reacts to actual traffic or the metrics it's configured to watch, so a `curl` (or equivalent request) to the staging URL is the only documented way to trigger scale-up. If you need to bypass KEDA entirely, that's a `kubectl scale`/ScaledObject edit outside this package's scope, and it will fight with KEDA's own reconciliation the next time it evaluates.

→ *See [PROJ-HOWTO.md#how-to-wake-up-a-keda-scaled-to-zero-service](PROJ-HOWTO.md#how-to-wake-up-a-keda-scaled-to-zero-service).*

## Caveats

### What happens if I run `staging-down` against the wrong namespace by mistake?

Every Helm release currently installed there gets uninstalled, with no confirmation prompt and no dry-run mode. Because the namespace comes from config/env (`K8_STAGING_NAMESPACE`) rather than a required explicit argument, a stale env var or wrong `--config` is enough to point it at a namespace you didn't mean to touch. Always run `staging-status` (or `helm list -n <ns>`) first to confirm what you're about to remove, especially after switching config files or shells.

→ *See [PROJ-HOWTO.md#how-to-tear-down-staging](PROJ-HOWTO.md#how-to-tear-down-staging).*

### If `staging-logs` reports "no pods running," does that mean something is broken?

Not necessarily — it's the expected, documented behavior when KEDA has scaled a service to zero replicas, and the tool exits cleanly rather than erroring. Check `staging-status` for ScaledObject/pod state before assuming a real failure; a `curl` to the service's staging URL is the documented way to wake it back up.

→ *See [PROJ-HOWTO.md#how-to-wake-up-a-keda-scaled-to-zero-service](PROJ-HOWTO.md#how-to-wake-up-a-keda-scaled-to-zero-service).*

## Trust

### Does `--assist` send my staging config or secrets to Claude?

It sends the invoked script's own header-comment documentation as context for your question — not your `infra-config.yaml` values, not cluster state, and not secrets. These tools never read or handle secret material themselves; that flows through the separate Infisical → k8s Secrets pipeline, entirely outside this package's code path. `--assist` also intercepts execution: the underlying staging command does not run when you pass it, so it can't leak live output either.

→ *See [PROJ-HOWTO.md#how-to-get-ai-assisted-help-from-any-staging--command](PROJ-HOWTO.md#how-to-get-ai-assisted-help-from-any-staging--command).*
