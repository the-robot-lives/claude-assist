# PROJ-FAQ — utilities/linux

Anticipated why/when/compared-to-what questions about this **grouping
directory** itself — the Makefile fan-out over Linux desktop-utility
children. Questions about a specific child's internals (e.g. queue-populator's
wake phrase, LLM cost, privacy model) belong in that child's own FAQ — see the
link at the bottom of each relevant answer here.

## Motivation

### Why does this directory exist instead of just putting queue-populator directly under `utilities/`?

Because Linux desktop apps are platform-gated compiled binaries, not the
shell scripts the rest of `utilities/` is built around, and grouping them
lets that gating live in one place. The flat `utilities/` tree is for
`share/k8-lib`-sourcing shell DevOps tools symlinked to `~/.local/bin`;
`utilities/linux/` (and its `utilities/osx/` sibling) hold compiled apps with
their own build tooling, install scripts, and platform-specific concerns
(PipeWire, GNOME autostart). Isolating them under a grouping dir means the
top-level Makefile fan-out doesn't need per-tool `uname` conditionals — each
child gates itself, and non-Linux hosts skip the whole branch cleanly.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions) for the full rationale.*

### Why a thin fan-out Makefile instead of each child registering itself with the monorepo root directly?

Because it keeps the monorepo root ignorant of what's inside `utilities/linux/` — it only needs to know
`make build`/`install`/etc. work here, not which children exist or what they
need. Adding, removing, or reordering children never touches root tooling;
only this directory's `SUBDIRS` line changes.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-linux-utility-to-this-group) to add one.*

## Fit

### I only care about queue-populator — do I need to understand this directory at all?

No. `make build`/`install`/`test` here (or at the monorepo root via
`make install-utilities`) reaches queue-populator automatically; you can work
entirely from `queue-populator/` and its own docs and never touch this
level's Makefile. This directory only matters once a second Linux utility
exists and you need to know which one to reach for.

→ *See [queue-populator/docs/PROJ-HOWTO.summary.md](../queue-populator/docs/PROJ-HOWTO.summary.md).*

### Is this the right place for a Linux CLI tool that isn't a GUI/desktop app?

Probably not — check `utilities/` (the flat shell-tool tree) first. This
grouping directory exists specifically for compiled, platform-gated desktop
applications with non-trivial install footprints (binaries, configs, models,
autostart units). A simple Linux-only shell script is better served by a
flat `utilities/` entry with an internal `uname` guard, matching the pattern
used elsewhere in that tree.

## Comparison

### How does this differ from `utilities/osx/`?

Same organizational pattern, opposite platform gate: `utilities/osx/` fans
out to macOS-gated children (including the original `queue-populator` this
one was ported from), while `utilities/linux/`'s children gate on Linux.
Where a tool exists on both platforms, config/queue schema choices are kept
in sync between the two ports by convention, not by shared code — there is
no shared crate or shared config file between the two directories today.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*

### How does this differ from the shell-script `utilities/` tools (docker-build, helm-upgrade, etc.)?

Those are direnv/`k8-lib`-sourcing shell scripts installed to `~/.local/bin`
by `make install-utilities` and used for infra/deploy workflows; children
under `utilities/linux/` are compiled desktop applications (Rust today) with
their own `install.sh`/`uninstall.sh`, config files, and — for
queue-populator — downloaded STT models and a GNOME autostart entry. They
participate in the same top-level `make` verbs but are otherwise unrelated
codebases with unrelated dependencies.

## Capability

### Can I run `make build` here without a Linux machine and expect it to do something?

No — every child gates on `uname` = Linux inside its own Makefile, so on
macOS or elsewhere every target silently no-ops (or prints a `skipped: no
target` line). This is expected, not a bug; the grouping directory itself has
no platform check because it delegates that responsibility to each child.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-test-or-install-every-linux-utility-at-once) gotchas.*

### Can I add a second Linux utility without touching the shared `mk/subdirs.mk` harness?

Yes. `../mk/subdirs.mk` is a generic fan-out shared by every grouping
directory in the monorepo (not just `linux/`); adding a child here means
creating its sibling folder and appending one name to this directory's
`SUBDIRS` line — no changes to the shared harness or to monorepo-root
tooling.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-linux-utility-to-this-group).*

## Caveats

### What happens if I ask for a `make` target a child doesn't support?

Nothing visibly wrong happens — the harness skips that child for that target
with no error, which can read as "it worked" when it actually did nothing.
If a target you expected didn't run, check `make help` inside the child
directly to see what it actually defines before assuming success.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-test-or-install-every-linux-utility-at-once) gotchas.*

### Does this directory track its own version/release history?

Only at the group level — Makefile shape, doc-set milestones, and which
children exist. Feature work, bug fixes, and behavior changes for
queue-populator itself are recorded in `queue-populator/CHANGELOG.md`, not
here; don't expect this directory's `CHANGELOG.md` to explain *why*
queue-populator behaves a certain way.

→ *See [CHANGELOG.md](../CHANGELOG.md) "Child Projects" table.*

## Trust

### If I delete this directory's Makefile, do I lose queue-populator's functionality?

You lose the convenience fan-out (`make build`/`install` from here, and the
monorepo-root `make install-utilities` reaching this child), but
queue-populator remains fully self-contained — it can still be built,
installed, and uninstalled directly via its own `Makefile`/`install.sh`
inside `queue-populator/`. Nothing about the child's runtime behavior depends
on this level.
