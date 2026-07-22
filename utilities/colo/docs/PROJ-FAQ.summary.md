# FAQ Index — utilities/colo

Question headings only, grouped by category. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).
Tool-internal questions live in [colo-utils/docs/PROJ-FAQ.summary.md](../colo-utils/docs/PROJ-FAQ.summary.md).

## Motivation
- Why does this directory exist instead of just having `colo-utils` live directly under `utilities/`?
- Why is there a group-level `Makefile` at all if it has no targets of its own?

## Fit
- When should I run `make -C utilities/colo install` instead of the repo root's `make install-utilities`?
- Is this the right place to add a new k8s dashboard tool (another `cluster-*`-style script)?

## Comparison
- How is `utilities/colo` different from `utilities/k8/cluster-utils`?
- How does adding a package here differ from adding one to `utilities/k8/cluster-utils` or another utility group?

## Capability
- Can I install just one tool out of `colo-utils` without pulling in the rest of the group?

## Caveats
- If I only run `make -C utilities/colo install`, will I have everything the colo tools need?
- Will group-level docs here tell me how to use a specific `colo-*`/`cluster-*` command?

## Trust
- If I add a package here, does it inherit any colo-specific security posture?
