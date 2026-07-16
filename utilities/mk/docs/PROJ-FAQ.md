# PROJ-FAQ — utilities/mk

Anticipated why/when/compared-to-what questions about the `mk` shared
Makefile-include package. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for procedures
and [PROJ-ARCH.md](PROJ-ARCH.md) for design rationale.

## Motivation

### Why would I use `subdirs.mk` instead of hand-writing recursive rules in each group Makefile?

Because it lets heterogeneous children coexist without every one of them
stubbing out every target. A hand-rolled recursive rule (`for d in $(SUBDIRS); do $(MAKE) -C $$d $@; done`)
fails the whole run the moment one child lacks the target you asked for; `subdirs.mk`
probes each child's `.PHONY` list first and skips silently, so a Rust crate that
only declares `build` and a shell-script dir that only declares `compile` and
`test` can sit in the same `SUBDIRS` line. The trade-off is two `make -pn`
probe invocations per child per target before the real one runs — slower than
blind recursion, and invisible unless you read the log line for each child.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-wire-a-new-makefile-group-into-the-subdir-fan-out-tree) to wire up a group.*

### Why probe `.PHONY` via `make -C dir -pn` instead of just running the target and ignoring failure?

Because "ignore failure" can't distinguish *target genuinely absent* from
*target present but broken* — swallowing both would hide real build breakage
as a silent skip. Parsing the `.PHONY:` line from `-pn` output is a cheap,
side-effect-free way to ask "does this target exist" before committing to run
it, so a failing `test` still fails loudly while a missing `test` just doesn't
run.

### Why does `build` fall back to `compile` instead of requiring every child to declare `build`?

Because script-only children (shell utilities, no compile step) naturally
only have a `compile` target, and forcing them to also alias `build := compile`
in every child Makefile would be repeated boilerplate for no benefit. The
fallback is a one-line special case in `subdirs.mk` instead of N repeated
aliases across children.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-understand-why-make-build-ran-compile-instead) for the mechanics.*

## Fit

### When is `subdirs.mk` the right tool for a new group of children?

When the group is a flat set of independent subprojects that each build/test/
install on their own, with no build-order dependency between them — e.g. the
`agent/` group's `dangerously-safe`, `skill-manage`, `claude-desktop-sandbox`,
etc. Any child can run alone via `make -C <dir>`; `subdirs.mk` just gives the
parent a uniform way to fan a target out to all of them plus a `make help`
listing.

### When is it the wrong tool?

When children have build-order dependencies on each other (child B needs
child A's output before it can build) — `subdirs.mk` loops sequentially over
`SUBDIRS` in declaration order but has no dependency graph, so it can't
express "build A, wait, then build B only if A succeeded and changed." For
that you want real Make prerequisites between explicit targets, not this
fan-out loop. It's also the wrong tool if you need parallel child builds:
the loop is a plain shell `for`, not `make -j`-aware, so children always run
one at a time regardless of `-j`.

## Comparison

### How does this differ from GNU Make's standard recursive-make pattern?

Standard recursive Make (`$(MAKE) -C $$d $@` for every `$$d`) assumes every
child supports every target and fails the run otherwise. `subdirs.mk` adds a
target-existence probe per child and a per-target skip, plus the
`build`→`compile` fallback — it's recursive Make with capability detection
layered on top, at the cost of the extra probe invocation described above.

### How does `check-subdirs.sh` differ from just noticing a child got silently skipped in the fan-out log?

`check-subdirs.sh` catches drift *before* a run — a child added to disk but
never added to a parent's `SUBDIRS` line — which the fan-out log wouldn't
show at all (the loop only iterates declared `SUBDIRS`, so an undeclared
child is invisible, not skipped-with-notice). Conversely a *declared* but
missing-target skip only shows up by reading fan-out output. Run the checker
for tree drift; read the fan-out log for capability gaps.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-check-the-makefile-tree-is-consistent).*

### Why is `check-subdirs.sh` a separate script instead of a Make target inside `subdirs.mk`?

Keeping it a standalone bash script lets it walk and validate a tree
independently of Make (useful in CI or a pre-commit hook where you'd rather
not shell out through `make` just to lint), and it keeps `subdirs.mk` itself
minimal — the include fragment only does dispatch, not tree validation.

## Capability

### Can `subdirs.mk` dispatch a custom target like `lint` or `docs`, not just build/compile/test/install/clean?

Yes — override `SUBDIR_TARGETS` before the `include` line and it fans out
exactly the same way, skip-if-absent included. There's no special casing
required beyond declaring the target name.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-fan-out-a-custom-target-not-buildcompiletestinstallclean).*

### Can a custom target get its own fallback substitution the way `build`→`compile` works?

No — the `build`→`compile` fallback is hardcoded as the one special case in
`subdirs.mk`; any other custom target with no matching child target is just
skipped, there's no generalized substitution table.

## Caveats

### What happens if a child's `Makefile` is malformed and the `-pn` probe itself errors?

The probe redirects stderr to `/dev/null` and the `awk` filter defaults
`found` to 0, so a probe that errors out looks identical to "target genuinely
absent" — the child is silently skipped rather than the run failing loudly.
This is the sharp edge of the skip-by-default design: a broken child
Makefile can hide as a normal opt-out. If a child stops showing up in a
fan-out run, check its Makefile parses cleanly with `make -C <dir> -pn` by
hand before assuming it just doesn't support the target.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-diagnose-a-child-that-stopped-showing-up-in-a-fan-out-run).*

### Does adding a directory to `SUBDIRS` fail loudly if the directory or its Makefile is missing?

Not from `subdirs.mk` itself — a `SUBDIRS` entry with no `Makefile` is
silently skipped by the fan-out loop's `[ -f "$$dir/Makefile" ]` guard, so a
typo'd directory name just never runs anything, with no error. `check-subdirs.sh`
is what turns this into a loud, non-zero-exit finding (`[MISSING-CHILD]`) —
it is not automatic, you have to run it.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-check-the-makefile-tree-is-consistent).*

## Trust

### Does `mk` touch secrets, credentials, or any state outside the Makefile tree it's dispatching over?

No. `subdirs.mk` and `check-subdirs.sh` are pure build-orchestration glue —
no dependency on `share/k8-lib`, `.infra-config.yaml`, direnv, or any
credential source. They read Makefiles on disk and shell out to `make`;
nothing here talks to Infisical, k8s, or the network.
