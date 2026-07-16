# PROJ-HOWTO — utilities/mk

Task-oriented guides for using the `mk` Make-include package. See
[PROJ-ARCH.md](PROJ-ARCH.md) for *why* it's built this way and
[PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where* things live.

## How to: wire a new Makefile group into the subdir-fan-out tree

**Goal:** make a new group of child projects (e.g. `utilities/newgroup/`) buildable/testable via `make build`, `make test`, etc. from its parent.
**Prereqs:** child directories already exist; each child that wants to participate has its own `Makefile` with `.PHONY` targets.

1. Create `utilities/newgroup/Makefile`:
   ```makefile
   SUBDIRS := child-a child-b
   SUBDIR_PREFIX := newgroup/
   SUBDIR_DESCRIPTION := New group utilities

   include ../mk/subdirs.mk
   ```
2. Add `newgroup` to the parent's `SUBDIRS` (e.g. `utilities/Makefile`).

**Verify:**
```bash
cd utilities && make help          # newgroup should appear under Subdirs
make newgroup                      # runs `make -C newgroup`
```
**Gotchas:**
- A child with no `Makefile` is silently skipped per-target (not an error) — it just won't show up in run output.
- `SUBDIR_PREFIX` is cosmetic only (log labeling); it does not affect dispatch.

## How to: add a child project to an existing group

**Goal:** make a new subproject participate in the existing `build`/`test`/`install`/`clean` fan-out without editing `subdirs.mk`.
**Prereqs:** the subproject has its own `Makefile` declaring the targets it supports.

1. Add the directory name to the group's `SUBDIRS` line, e.g. in `utilities/agent/Makefile`:
   ```makefile
   SUBDIRS := claude-assist claude-desktop-sandbox dangerously-safe mallm media-tool run-claude skill-manage new-tool
   ```
2. Ensure `new-tool/Makefile` declares `.PHONY` for any target it wants dispatched (e.g. `test`, `install`).

**Verify:**
```bash
cd utilities && make agent          # "new-tool" appears in the run, or a "skipped: no target" notice per target it lacks
```
**Gotchas:**
- Forgetting this step is exactly what `check-subdirs.sh` catches — see below.

## How to: check the Makefile tree is consistent

**Goal:** catch drift between what's on disk and what parent Makefiles declare — before it silently breaks `make install-utilities`.
**Prereqs:** none; pure bash + find over the tree.

1. Run from the repo's `utilities/` root (or pass a root path):
   ```bash
   cd utilities && ./mk/check-subdirs.sh .
   ```
2. Wire it into CI/pre-commit as a gate (non-zero exit on any finding):
   ```bash
   ./mk/check-subdirs.sh . || exit 1
   ```

**Verify:** clean tree prints `Makefile tree structure is consistent.` and exits `0`.
**Gotchas:**
- `[MISSING-FROM-PARENT] <parent>/Makefile: '<dir>' is present ... but not in SUBDIRS` → add `<dir>` to that parent's `SUBDIRS` line (see the guide above).
- `[MISSING-SUBDIRS] <parent>/Makefile: has no SUBDIRS declaration` → parent has Makefile-bearing children but never declares `SUBDIRS :=` at all; add one (can be empty on purpose if truly unrelated files).
- `[MISSING-CHILD] <parent>/Makefile: listed child '<x>' has no Makefile` → either remove `<x>` from `SUBDIRS` or add the missing `Makefile`.
- The checker prunes `mk/` itself from scanning, so this package never flags itself.

## How to: fan out a custom target (not build/compile/test/install/clean)

**Goal:** dispatch a project-specific target (e.g. `lint`, `docs`) across a group's children using the same skip-if-absent logic.
**Prereqs:** children that support the target declare it in their own `Makefile` `.PHONY` list.

1. Override `SUBDIR_TARGETS` in the group Makefile before including `subdirs.mk`:
   ```makefile
   SUBDIRS := child-a child-b
   SUBDIR_TARGETS := build compile test install clean lint
   include ../mk/subdirs.mk
   ```
2. Run it: `make lint` from that group's directory.

**Verify:** `make help` in that directory lists `lint` under `Targets:`.
**Gotchas:** only `build` gets the `compile` fallback — a custom target with no matching child target is just skipped, there's no analogous substitution for other target names.

## How to: diagnose a child that stopped showing up in a fan-out run

**Goal:** figure out whether a child directory is intentionally opted out of a target or its `Makefile` is broken and being silently skipped.
**Prereqs:** the child directory and its `Makefile` exist on disk (if not, see "check the Makefile tree is consistent" above — that's a different failure mode).

1. Probe the child by hand exactly the way `subdirs.mk` does, substituting the target you expected to run (`build`, `test`, `install`, etc.):
   ```bash
   make -C <child-dir> -pn <target> 2>/dev/null | grep '^\.PHONY:'
   ```
2. Compare the output:
   - `.PHONY:` line lists the target → it's not a skip; something else is wrong (check the fan-out log for `(target -> compile)` fallback or a genuine error further up).
   - `.PHONY:` line is present but doesn't list the target → genuine opt-out, expected `skipped: no target` behavior, nothing to fix.
   - The command itself errors or prints nothing → the child's `Makefile` is malformed; `subdirs.mk`'s probe redirects stderr to `/dev/null` and treats a parse error identically to "target absent," so this is the sharp edge — fix the child `Makefile` syntax, don't assume it's just opting out.

**Verify:** after fixing a malformed `Makefile`, rerun the probe command — the target now appears in `.PHONY:` — then rerun the real fan-out (`make <target>` from the parent) and confirm the child's line no longer reads `skipped: no target`.
**Gotchas:**
- `check-subdirs.sh` does **not** catch this — it only checks tree drift (declared-but-missing children, undeclared-but-present children), not whether a listed child's `Makefile` parses cleanly. A malformed Makefile on a correctly-declared child is invisible to the checker.
- Don't drop the `2>/dev/null` when comparing against real fan-out behavior — with it removed you'll see the parse error, but that changes what you're diagnosing (the actual fan-out always suppresses it).

## How to: understand why `make build` ran `compile` instead

**Goal:** avoid confusion when a group's log line reads `(build -> compile)`.
**Prereqs:** none.

This is intentional, not a bug: `subdirs.mk` probes each child for a `build` target first; if absent but `compile` is declared, it substitutes `compile` so script-only children (which typically only declare `compile`) still respond to a top-level `make build`.

**Verify:** the fan-out log line for that child explicitly says `(build -> compile)` when this happens; a plain `(build)` means the child had its own `build` target.
**Gotchas:** if a child declares neither, you'll see `skipped: no target` — that's not a fallback failure, the child genuinely opts out of `build`.
