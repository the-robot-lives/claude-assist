# PROJ-HOWTO — utilities/linux

Task-oriented guides for this **grouping directory**. This level is a thin
Makefile fan-out over self-contained Linux desktop-utility children (today:
`queue-populator/`) — see [PROJ-ARCH](PROJ-ARCH.summary.md) for why. Guides
here cover cross-tool workflows (build/install fan-out, adding a new Linux
utility) and which-tool-when. **Child internals — installing, configuring, or
troubleshooting queue-populator itself — live in its own docs; this file
links out rather than duplicating them.**

## How to: build, test, or install every Linux utility at once

**Goal:** run one command from `utilities/linux/` and have it fan out to
every child project's own build/test/install target.
**Prereqs:** none beyond whatever each child needs (e.g. `cargo` for
queue-populator — see its own [PROJ-HOWTO](../queue-populator/docs/PROJ-HOWTO.summary.md)).

1. From this directory, run any of:
   ```bash
   make build     # or: compile, test, install, clean
   ```
2. The shared `../mk/subdirs.mk` harness iterates `SUBDIRS` (currently just
   `queue-populator`), checks each child Makefile for that target (falling
   back from `build` to `compile` if `build` isn't defined), and skips
   cleanly if the target doesn't apply — e.g. non-Linux hosts, where child
   Makefiles self-gate on `uname`.
3. To see targets/subdirs without running anything:
   ```bash
   make help
   ```

**Verify:** output shows one `--- linux/<child> (<target> -> <resolved>) ---`
banner per subdir, then that child's own build output (or a `skipped: no
target` line, which is expected/harmless on the wrong platform).
**Gotchas:**
- Nothing happens and no error appears if a child doesn't define the target
  you asked for (or its Makefile doesn't gate it in) — check `make help`
  inside the child if a target you expected is silently skipped.
- This is invoked automatically by `make install-utilities` at the monorepo
  root; you don't need to `cd` here for a full-repo install.

## How to: work on a single child utility directly

**Goal:** skip the fan-out and build/install/test just one child.
**Prereqs:** none.

1. Either `cd` into the child and run its own `make` targets, or from here:
   ```bash
   make queue-populator     # invokes that child's default Makefile target
   ```
2. For anything beyond build/install — configuration, usage, troubleshooting
   — go straight to that child's own HOWTO/FAQ, not this file:
   [queue-populator/docs/PROJ-HOWTO.summary.md](../queue-populator/docs/PROJ-HOWTO.summary.md) ·
   [queue-populator/docs/PROJ-FAQ.summary.md](../queue-populator/docs/PROJ-FAQ.summary.md)

**Verify:** child's own build/install output completes without error.
**Gotchas:** there's currently one child, so "which tool for task X" has a
single answer — queue-populator. Revisit this section once a second Linux
utility lands (see below).

## How to: add a new Linux utility to this group

**Goal:** wire a new self-contained Linux desktop tool into the shared
build/install fan-out.
**Prereqs:** the new tool lives in its own sibling folder here and owns a
Makefile defining whichever of `build`/`compile`/`test`/`install`/`clean` it
supports, plus its own `docs/` (PROJ-ARCH, PROJ-LAYOUT, etc. — same shape as
`queue-populator/docs/`).

1. Create the sibling directory, e.g. `utilities/linux/my-new-tool/`, with
   its own Makefile and docs.
2. Add it to `SUBDIRS` in this directory's `Makefile`:
   ```make
   SUBDIRS := queue-populator my-new-tool
   ```
3. No other change is needed here — `../mk/subdirs.mk` picks it up
   automatically for every target.

**Verify:** `make help` lists the new subdir; `make build` (or `compile`)
shows a banner for it and runs its Makefile.
**Gotchas:**
- Keep platform gating inside the *child's* Makefile (`uname` check), not
  here — this level stays platform-agnostic and routes unconditionally.
- If the tool has a macOS counterpart, mirror config/queue schema choices
  with the sibling under `utilities/osx/` (see PROJ-ARCH "Ecosystem Fit").
- Don't document the child's install/usage/troubleshooting here — that
  belongs in the child's own PROJ-HOWTO/PROJ-FAQ.

## Which tool for which task?

Only one child today. Use this table as the group grows:

| I want to... | Use | Docs |
|---|---|---|
| Capture voice memos / route my mic into apps by voice on Ubuntu GNOME + PipeWire | `queue-populator` | [Its HOWTO](../queue-populator/docs/PROJ-HOWTO.summary.md) |
