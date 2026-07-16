# FAQ Summary — utilities/k8

Question headings only, grouped by category. Companion to
[PROJ-FAQ.md](PROJ-FAQ.md) — cheap relevance check before opening the full
file. Group-level only; per-package questions live in each child's own FAQ
summary.

## Motivation
- Why is this split into seven packages instead of one CLI?
- Why does every package share `k8-lib` instead of each vendoring its own helpers?
- Why does the doc structure keep changing (ARCH/LAYOUT, then HOWTO, then FAQ)?

## Fit
- Why doesn't `deploy-service` handle a multi-image composite release (frontend+backend) in one call?
- When should I use these tools instead of raw `kubectl`/`helm`/`docker`?
- Which of the seven packages do I actually need day to day?

## Comparison
- How does this toolset differ from k9s, Lens, or ArgoCD?
- How do the group-level docs differ from each package's own docs?

## Capability
- Can I install or use one package without the other six?
- Does `--assist` (the AI help flag) work the same across all seven packages?

## Caveats
- What happens if group-level docs and a child's docs disagree?
- Is it safe to re-run `make install-utilities` after only one package changed?
- Why did six repos get merged as subtrees instead of one rewritten monorepo package?
- Why must Infisical secrets be bootstrapped before recovering a cluster's Helm releases after a disaster?
- Why does config discovery walk multiple candidate locations instead of requiring one canonical `.infra-config.yaml` path?

## Trust
- Does anything in this group send my cluster config or secrets anywhere?
