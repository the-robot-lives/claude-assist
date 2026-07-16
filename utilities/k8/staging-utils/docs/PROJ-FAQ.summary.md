# PROJ-FAQ summary — staging-utils

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for answers.

## Motivation

- Why would I use `staging-up`/`staging-down` instead of just running `helm`/`kubectl` directly?
- Why does `staging-up` always pass `--force`?
- Why is there no `lib/` in this package — why depend on an external `k8-lib`?
- Why would I use `staging-status` instead of running `kubectl get pods`/`helm list`/`kubectl get scaledobjects` separately?

## Fit

- Why doesn't `staging-up` accept `--config` the way the other tools do?
- When is `staging-utils` the wrong tool to reach for?
- Can I point these tools at a namespace other than the default `staging`?

## Comparison

- How does `staging-down` differ from running `helm uninstall --all -n staging` myself?
- How does `staging-up` differ from calling `helm-upgrade --env stage --force` directly?

## Capability

- Can `staging-logs` tail more than one service at once?
- Can `staging-down` uninstall just one release instead of everything?
- Can I preview what `staging-down` will remove before it actually deletes anything?
- Can I force a KEDA-scaled-to-zero service to wake up without sending it real traffic?

## Caveats

- What happens if I run `staging-down` against the wrong namespace by mistake?
- If `staging-logs` reports "no pods running," does that mean something is broken?

## Trust

- Does `--assist` send my staging config or secrets to Claude?
