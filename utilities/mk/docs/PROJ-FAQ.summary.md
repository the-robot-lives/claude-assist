# PROJ-FAQ.summary — utilities/mk

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use `subdirs.mk` instead of hand-writing recursive rules in each group Makefile?
- Why probe `.PHONY` via `make -C dir -pn` instead of just running the target and ignoring failure?
- Why does `build` fall back to `compile` instead of requiring every child to declare `build`?

## Fit
- When is `subdirs.mk` the right tool for a new group of children?
- When is it the wrong tool?

## Comparison
- How does this differ from GNU Make's standard recursive-make pattern?
- How does `check-subdirs.sh` differ from just noticing a child got silently skipped in the fan-out log?
- Why is `check-subdirs.sh` a separate script instead of a Make target inside `subdirs.mk`?

## Capability
- Can `subdirs.mk` dispatch a custom target like `lint` or `docs`, not just build/compile/test/install/clean?
- Can a custom target get its own fallback substitution the way `build`→`compile` works?

## Caveats
- What happens if a child's `Makefile` is malformed and the `-pn` probe itself errors?
- Does adding a directory to `SUBDIRS` fail loudly if the directory or its Makefile is missing?

## Trust
- Does `mk` touch secrets, credentials, or any state outside the Makefile tree it's dispatching over?
