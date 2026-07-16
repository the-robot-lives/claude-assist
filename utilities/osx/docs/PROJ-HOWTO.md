# How To — utilities/osx

`utilities/osx` is a **grouping directory**: it fans out `make` targets to two
unrelated macOS-host tools (`fstab/`, `queue-populator/`) and has no behavior of
its own beyond that. Tasks here cover the group-level fan-out and picking the
right child; each child's own tasks (install, configure, day-to-day use,
troubleshooting, uninstall) live in its own HOWTO — link out below rather than
duplicating them.

- For *why* this directory exists and how the fan-out works: [PROJ-ARCH.md](PROJ-ARCH.md)
- For the directory map: [PROJ-LAYOUT.md](PROJ-LAYOUT.md)

## How to: figure out which tool I need

**Goal:** decide between `fstab/` and `queue-populator/` (or use both) for the macOS task in front of you.
**Prereqs:** none.

| I want to... | Use |
|---|---|
| Have a volume (APFS or NTFS) auto-mount at a fixed path on boot, like Linux `/etc/fstab` | [`fstab/`](../fstab/docs/PROJ-HOWTO.summary.md) |
| Get read-write access to an NTFS drive without native macOS support | [`fstab/`](../fstab/docs/PROJ-HOWTO.summary.md) |
| Capture spoken voice memos and have an LLM file them into queues | [`queue-populator/`](../queue-populator/docs/PROJ-HOWTO.summary.md) |
| Route my live voice into another app (Claude/Codex/etc.) as a selectable virtual mic | [`queue-populator/`](../queue-populator/docs/PROJ-HOWTO.summary.md) |

They share no code, config, or install path — pick one, or run both independently.

**Verify:** you've opened the linked child's HOWTO summary and found your task listed there.
**Gotchas:**
- Don't look for a group-level config file or install script — there isn't one; each child installs itself (see below).

## How to: build/test/install/clean every osx utility in one command

**Goal:** run a single `make` target from `utilities/osx/` and have it fan out to every child that supports it, skipping ones that don't.
**Prereqs:** none — this Makefile has no dependencies of its own.

1. From this directory, run any of:
   ```bash
   cd utilities/osx
   make build     # falls back to `compile` per-child if `build` isn't defined
   make test
   make install
   make clean
   ```
2. To see the available targets and children without running anything:
   ```bash
   make help
   ```

**Verify:** output shows one `--- osx/<child> (<target> -> <resolved-target>) ---` banner per child, or `... skipped: no target ...` for children that don't implement it. Example on a non-Darwin host:
```
--- osx/fstab (build skipped: no target) ---
--- osx/queue-populator (build -> compile) ---
```
**Gotchas:**
- **Not on macOS:** `fstab` targets require Darwin-specific tooling and no-op or skip on Linux; `queue-populator` prints a "skipped on Linux" notice for `compile`/`build`. This is expected — build/test the child directly on a Mac.
- **`install` needs root for `fstab`:** the group fan-out does *not* elevate privileges for you. Run `make install` for that child as documented in its own HOWTO (it uses `sudo` internally where required), or `cd fstab && sudo make install` directly.
- **A target you expect "does nothing":** the fan-out only runs a target if the child Makefile declares it `.PHONY`. If a child is missing a target you need, add it there — this Makefile has no logic to patch around it.

## How to: run a target against just one child from the group root

**Goal:** target `fstab` or `queue-populator` specifically without affecting the other.
**Prereqs:** none.

1. Either `cd` into the child and use its own Makefile directly (see its HOWTO), or invoke it by name from here:
   ```bash
   make fstab             # equivalent to: make -C fstab
   make queue-populator    # equivalent to: make -C queue-populator
   ```
2. For child-specific targets (e.g. `fstab`'s `status`, `uninstall`), `cd` into the child — the group Makefile only forwards the five standard targets (`build compile test install clean`).

**Verify:** `make -C fstab help` (or the equivalent for `queue-populator`) shows that child's full target list.
**Gotchas:**
- The group Makefile can't run a child-only target like `status` — it only knows `build/compile/test/install/clean`. Run those directly against the child.

## Child task indexes

Full task lists live with each child — do not re-derive them here:

- **fstab** — [PROJ-HOWTO.summary.md](../fstab/docs/PROJ-HOWTO.summary.md) — install & first mount, NTFS rw/ro, applying config edits live, recovering from a changed volume UUID, uninstalling.
- **queue-populator** — [PROJ-HOWTO.summary.md](../queue-populator/docs/PROJ-HOWTO.summary.md) — build/install/verify, LLM provider config, day-to-day memo capture, wake-phrase/queue-path customization, virtual-mic voice routing, adding queue categories, debug logging, uninstalling.
