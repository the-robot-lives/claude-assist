# How-To — utilities/colo

`utilities/colo` is a **grouping directory** (see [PROJ-ARCH](PROJ-ARCH.md) /
[PROJ-LAYOUT](PROJ-LAYOUT.md)): it has no runtime tools of its own, just a
delegating `Makefile` over child packages. This file covers group-level tasks —
installing across the group, extending it with a new package, and finding the
right child doc for a task. **Tool-internal usage (which `cluster-*`/`colo-*`
command to run, their flags, config) lives in the child's own HOWTO/FAQ —
linked below, not repeated here.**

## How to: install every colo-related tool from this group

**Goal:** get all tools shipped under `utilities/colo` (today: `colo-utils`'s
`colo-*` helpers) onto your `PATH` in one command.
**Prereqs:** none beyond a writable `~/.local/bin`.

1. From the repo root:
   ```bash
   make -C utilities/colo install
   ```
   This fans out to every entry in `SUBDIRS` (currently only `colo-utils`) and
   runs each child's own `install` target.
2. For the `cluster-*` dashboards, use the monorepo root's aggregate target
   instead — it installs `cluster-*` (from `utilities/k8/cluster-utils`) and
   the shared `k8-lib` alongside every other utility group:
   ```bash
   make install-utilities   # from repo root
   ```

**Verify:**
```bash
which colo-sync colo-deploy-relay colo-local-model-link
```
**Gotchas:**
- Running `make -C utilities/colo install` only reaches packages listed in
  this directory's `SUBDIRS` — it does **not** install `cluster-*` (those live
  under `utilities/k8/cluster-utils`, a sibling group). Use root
  `make install-utilities` for the full tool set in one shot.
- `colo-utils`'s own `make install` (run from inside `colo-utils/`) installs
  only its `colo-*` binaries by design — see
  [colo-utils FAQ: why does `make install` here only install `colo-*`?](../colo-utils/docs/PROJ-FAQ.md).

## How to: figure out which tool covers a colo/cluster task

**Goal:** land on the right command without reading every child README.
**Prereqs:** none.

1. Start from the child's condensed task list — it's the fastest index:
   [colo-utils/docs/PROJ-HOWTO.summary.md](../colo-utils/docs/PROJ-HOWTO.summary.md).
2. For "should I use X or Y" comparisons (e.g. `cluster-nodes` vs
   `cluster-resources`, `colo-sync` vs raw `rsync`), check the child FAQ's
   **Fit** and **Comparison** sections:
   [colo-utils/docs/PROJ-FAQ.summary.md](../colo-utils/docs/PROJ-FAQ.summary.md).
3. If the task isn't about `colo-utils` at all — inspecting the k8s cluster
   itself via `cluster-*` dashboards is documented in
   `utilities/k8/cluster-utils/docs/` (a separate group), not here.

**Verify:** you land on a single named tool + doc section before running
anything.
**Gotchas:**
- `colo-utils/bin/` ships copies of the `cluster-*` scripts too (so the
  package works standalone), but the canonical source and docs for those
  dashboards live in `utilities/k8/cluster-utils/` — treat that as the
  source of truth for `cluster-*` behavior.

## How to: install just one colo-utils binary without the rest of the group

**Goal:** get a single `colo-*` (or `cluster-*`) binary from
`colo-utils/bin/` onto your `PATH` without installing every binary the group
ships.
**Prereqs:** a writable `~/.local/bin` (or your preferred `INSTALL_DIR`) on
`PATH`.

1. Neither this directory's `Makefile` nor `colo-utils`' own `make install`
   support installing a subset — `colo-utils`' `install` target loops over
   every `bin/colo-*` file. For one binary, symlink it directly instead:
   ```bash
   ln -sf "$(pwd)/utilities/colo/colo-utils/bin/colo-sync" ~/.local/bin/colo-sync
   ```
   (run from the repo root, or use an absolute path to `utilities/colo/colo-utils/bin/`).
2. Alternatively, if you're fine installing the whole `colo-utils` package
   (still cheaper than the root aggregate), run its own `install` target and
   ignore the binaries you don't need:
   ```bash
   make -C utilities/colo/colo-utils install
   ```

**Verify:**
```bash
which colo-sync   # or whichever binary you linked/installed
```
**Gotchas:**
- `colo-utils`' `install` target only globs `bin/colo-*` — it does **not**
  copy the vendored `cluster-*` scripts even when you run the whole-package
  install; symlink those individually the same way if you need one.
- A manual symlink isn't tracked by any `Makefile`, so it won't be
  cleaned up by `make clean`/uninstall tooling — remove it yourself if the
  binary is later renamed or removed upstream.

## How to: add a new package to the colo group

**Goal:** register a new colo-related utility package so it installs
alongside `colo-utils` via this directory's `Makefile`.
**Prereqs:** the new package lives under `utilities/colo/<new-pkg>/` with its
own `Makefile` exposing `install` (and ideally `build`/`compile`/`test`/`clean`
as applicable — see [`../mk/subdirs.mk`](../../mk/subdirs.mk) for what
targets fan out).

1. Create the package directory with its own `Makefile`, `README.md`, and
   `docs/` (PROJ-ARCH/PROJ-LAYOUT/PROJ-HOWTO at minimum, per the sibling
   `colo-utils` layout).
2. Add it to `SUBDIRS` in `utilities/colo/Makefile`:
   ```make
   SUBDIRS := colo-utils <new-pkg>
   ```
3. Update this group's [PROJ-ARCH.md](PROJ-ARCH.md) and
   [PROJ-LAYOUT.md](PROJ-LAYOUT.md) component tables to list the new child.

**Verify:**
```bash
make -C utilities/colo help    # confirm <new-pkg> appears under "Subdirs:"
make -C utilities/colo install # confirm it installs cleanly
```
**Gotchas:**
- `subdirs.mk` skips any target a child's `Makefile` doesn't declare `.PHONY`
  — if `install` silently no-ops for the new package, check its `Makefile`
  lists `install` in `.PHONY`.
- Don't fold the new package's internals into this file — its own
  `docs/PROJ-HOWTO.md` is the source of truth; this file only tracks that it
  exists and how it's installed.
