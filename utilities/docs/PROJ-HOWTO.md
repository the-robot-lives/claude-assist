# PROJ-HOWTO — utilities/ (toolbox root)

Task-oriented guides for the toolbox as a whole — cross-group workflows and
toolbox-wide questions. This level has **no runtime code** of its own (see
[PROJ-ARCH.md](PROJ-ARCH.md)), so it does not restate any child tool's usage.
For a task inside one group or tool, jump straight to that child's own
`docs/PROJ-HOWTO.md` — the [group index](#per-group-how-to-guides) at the
bottom links every one.

## How to: install every utility in the toolbox in one shot

**Goal:** get every DevOps CLI tool (all ten groups) onto `PATH` (shared libs
into `~/.local/share/`) without visiting each group individually.
**Prereqs:** none beyond each group's own build prereqs (Rust/Cargo, Node,
Swift toolchain on macOS, etc. — see [PROJ-LAYOUT.md](PROJ-LAYOUT.md)).

1. From the **repo root**:
   ```bash
   make install-utilities
   ```
   Or from `utilities/` directly:
   ```bash
   make install
   ```
2. This fans out `install` across `SUBDIRS_NO_OSX` (`agent shell k8 terraform
   database colo start-app-scaffold linux` — `osx` is skipped off-macOS since
   it uses its own sudo/LaunchDaemon installers).

**Verify:**
```bash
which docker-build dc repo-lock deploy-service   # spot-check a few known binaries
```
**Gotchas:**
- A group whose Makefile is missing prints `--- <dir> (missing <dir>/Makefile)
  ---` and is silently skipped — not a failure, but nothing installs from it.
- `osx/` never runs from this target on Linux; on macOS it still needs its own
  `make -C osx install` (see [osx's HOWTO](../osx/docs/PROJ-HOWTO.md)).
- Installing everything doesn't configure anything — infra-facing groups
  (`k8`, `database`, `terraform`, `colo`) still need `.infra-config.yaml` +
  `.envrc.k8.dc` resolved before their commands work; see each group's HOWTO.

## How to: install just one utility group without the other nine

**Goal:** get one group's tools onto `PATH` (e.g. only `k8`) without running
the full toolbox-wide `make install-utilities` fan-out.
**Prereqs:** that group's own build prereqs — see its `PROJ-LAYOUT.md`.

1. From the **repo root** or `utilities/`, target the group directly:
   ```bash
   make -C utilities/k8 install
   ```
2. Most groups let you go one level deeper into a single child tool inside
   that group — check the group's own `PROJ-HOWTO.md` for the child-level
   target (e.g. `make -C utilities/k8/cluster-utils install`).

**Verify:**
```bash
which <tool-from-that-group>   # e.g. `which docker-build` after installing k8
```
**Gotchas:**
- This does not run any other group's `install` — a tool from a different
  group that you assumed came along for free won't be on `PATH` until you
  install that group too (or run the full `make install-utilities`).
- If the group name is wrong or the directory has no `Makefile`, `make -C`
  fails loudly (`No rule to make target`) rather than silently skipping the
  way the top-level fan-out does — see the next guide for that distinction.

## How to: confirm every group actually installed after `make install-utilities`

**Goal:** catch the case where `make install-utilities` reported overall
success but one or more groups were silently skipped (missing/malformed
Makefile) rather than actually installed.
**Prereqs:** none.

1. Re-run the install and read the per-group lines, not just the exit code —
   a skipped group prints `--- <dir> (missing <dir>/Makefile) ---` instead of
   running `install`:
   ```bash
   make install-utilities
   ```
2. Independently verify the Makefile tree structure is sound:
   ```bash
   ./mk/check-subdirs.sh .
   ```

**Verify:** `check-subdirs.sh` prints `Makefile tree structure is consistent.`
with no warnings; every group in `SUBDIRS` shows a real `(install -> install)`
line in step 1, not a "missing Makefile" line.
**Gotchas:**
- `check-subdirs.sh` only checks *Makefile* wiring (a group is declared and
  has a Makefile) — it does not check that `docs/` scaffolding exists or that
  the install actually produced working binaries; pair it with the `which`
  spot-check from [install every utility § Verify](#how-to-install-every-utility-in-the-toolbox-in-one-shot).
- A skip is not a failure exit code — `make install-utilities` can report
  success as a whole even with one or more groups skipped; you have to read
  the output, not just check `$?`.

## How to: find the right tool for a task across the whole toolbox

**Goal:** given a devops need ("I want to snapshot a Valkey volume", "I want
a reverse SSH tunnel"), find the one command that does it without grepping
ten directories.
**Prereqs:** none.

1. Start at the root [OVERVIEW.md](../OVERVIEW.md) — one table per group,
   maturity-rated, linking each tool's `PROJ-ARCH.md#overview`.
2. If the group is clear but not the specific tool, every group's own HOWTO
   has a "pick the right tool for X" guide with a decision table:
   - [agent](../agent/docs/PROJ-HOWTO.md), [k8](../k8/docs/PROJ-HOWTO.md),
     [shell](../shell/docs/PROJ-HOWTO.md), [database](../database/docs/PROJ-HOWTO.md),
     [terraform](../terraform/docs/PROJ-HOWTO.md), [colo](../colo/docs/PROJ-HOWTO.md)

**Verify:** you land on a single command name, not a shortlist.
**Gotchas:** some names collide in spirit across groups (e.g. `cluster-utils`
dashboards live under `k8/`, not `colo/`, even though colo is cluster-adjacent
— the colo HOWTO calls this out explicitly).

## How to: push 3rd-party Docker images to ops.noizu.com

**Goal:** build (forked/extended services) or mirror (upstream images used
as-is) the vendored 3rd-party image set to the internal registry.
**Prereqs:** `$REPOS_3RD_DIR` checked out (default
`$HOME/Github/infra/noizu-infra/repos/3rd`); a multi-arch buildx builder
named `noizu-multi` (override with `$DOCKER_BUILDER`) for the build path.

1. Preview first — no changes made:
   ```bash
   ./push-3rd-party-images.sh --dry-run
   ```
2. Push everything, or narrow to specific images / a glob:
   ```bash
   ./push-3rd-party-images.sh                     # push all
   ./push-3rd-party-images.sh bottlecrm docmost    # named images only
   ./push-3rd-party-images.sh --filter "ghost*"    # glob filter
   ```
3. Split build vs. mirror phases if you only need one:
   ```bash
   ./push-3rd-party-images.sh --build-only
   ./push-3rd-party-images.sh --mirror-only
   ```

**Verify:** `--dry-run` output lists the exact targets it would build/mirror;
compare against `$REPOS_3RD_DIR` contents before running for real.
**Gotchas:**
- Wrong/missing `$REPOS_3RD_DIR` → build targets silently resolve to nothing
  found for that service; check the env var first if a service is missing.
- Multi-arch builds need the named builder to already exist
  (`docker buildx create --name noizu-multi ...`) — this script does not
  create it for you.

## How to: work safely with several concurrent agent sessions in this repo

**Goal:** avoid two Claude/agent sessions racing on the same files or the
shared git index — a toolbox-wide concern, not one group's problem, since
every group here is routinely edited by parallel fleet sessions (see
[CLAUDE.md](../../CLAUDE.md) "Be frugal" / sub-agent delegation model).
**Prereqs:** `repo-lock` installed (`shell/` group).

1. Full setup + first lock walkthrough lives in repo-lock's own guide — this
   is the one child-level guide worth jumping to directly from the root,
   since it's the concurrency-safety mechanism for the *entire* monorepo:
   → [shell/repo-lock/docs/howto/first-hour.md](../shell/repo-lock/docs/howto/first-hour.md)
2. Combined with commit safety across sessions:
   → [shell/docs/howto/multi-agent-checkout.md](../shell/docs/howto/multi-agent-checkout.md)

**Verify:** `repo-lock list` shows your session's active lane before you start
editing a subtree.
**Gotchas:** locks are advisory — a session that doesn't check `repo-lock
list`/doesn't install the commit hook can still clobber another session's
work; it only helps sessions that participate.

## How to: add a new top-level utility group

**Goal:** stand up a brand-new group directory (e.g. `utilities/newgroup/`)
so it participates in `make install-utilities` and shows up in the toolbox
catalog — the root-level half of the job; the Make-fan-out mechanics
themselves are `mk/`'s territory and not repeated here.
**Prereqs:** the group's child tool(s) already exist with their own
Makefiles.

1. Wire the Make fan-out (full mechanics + verification):
   → [mk/docs/PROJ-HOWTO.md § wire a new Makefile group](../mk/docs/PROJ-HOWTO.md#how-to-wire-a-new-makefile-group-into-the-subdir-fan-out-tree)
2. Add `newgroup` to `SUBDIRS` in the root `utilities/Makefile` (and to the
   `osx`-exclusion filter only if it's a macOS-only group).
3. Add a doc scaffold under `newgroup/docs/` (`PROJ-ARCH`, `PROJ-LAYOUT`,
   `PROJ-FAQ`, `PROJ-HOWTO` + summaries) — every existing group has one; see
   any sibling group for the pattern.
4. Add a row to root [OVERVIEW.md](../OVERVIEW.md) so the group shows up in
   the catalog table.

**Verify:**
```bash
./mk/check-subdirs.sh .        # must print "Makefile tree structure is consistent."
make -n install                # confirm newgroup appears in the dry-run fan-out list
```
**Gotchas:**
- Skipping step 4 means the group installs fine but is invisible to anyone
  scanning `OVERVIEW.md` for "what tools exist here."
- `check-subdirs.sh` only checks *Makefile* wiring, not doc scaffolding —
  a missing `docs/` dir won't show up as an error there.

## Per-group HOW-TO guides

- [agent](../agent/docs/PROJ-HOWTO.md) — AI-coding-agent workflow tooling
- [colo](../colo/docs/PROJ-HOWTO.md) — colo-host helpers
- [database](../database/docs/PROJ-HOWTO.md) — DB CLIs
- [k8](../k8/docs/PROJ-HOWTO.md) — build → push → deploy → operate pipeline
- [linux](../linux/docs/PROJ-HOWTO.md) — Linux-only desktop apps
- [mk](../mk/docs/PROJ-HOWTO.md) — shared Make harness
- [osx](../osx/docs/PROJ-HOWTO.md) — macOS-only apps
- [shell](../shell/docs/PROJ-HOWTO.md) — shell & terminal utilities
- [start-app-scaffold](../start-app-scaffold/docs/PROJ-HOWTO.md) — project generator
- [terraform](../terraform/docs/PROJ-HOWTO.md) — Terraform helpers
