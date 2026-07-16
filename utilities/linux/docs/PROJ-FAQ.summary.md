# FAQ Summary — utilities/linux

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md). Child
(queue-populator) questions live in its own
[FAQ summary](../queue-populator/docs/PROJ-FAQ.summary.md).

## Motivation
- Why does this directory exist instead of just putting queue-populator directly under `utilities/`?
- Why a thin fan-out Makefile instead of each child registering itself with the monorepo root directly?

## Fit
- I only care about queue-populator — do I need to understand this directory at all?
- Is this the right place for a Linux CLI tool that isn't a GUI/desktop app?

## Comparison
- How does this differ from `utilities/osx/`?
- How does this differ from the shell-script `utilities/` tools (docker-build, helm-upgrade, etc.)?

## Capability
- Can I run `make build` here without a Linux machine and expect it to do something?
- Can I add a second Linux utility without touching the shared `mk/subdirs.mk` harness?

## Caveats
- What happens if I ask for a `make` target a child doesn't support?
- Does this directory track its own version/release history?

## Trust
- If I delete this directory's Makefile, do I lose queue-populator's functionality?
