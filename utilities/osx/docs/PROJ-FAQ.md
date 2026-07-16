# utilities/osx — FAQ

`utilities/osx` is a **grouping directory** — a thin fan-out `Makefile` over two
unrelated macOS-host tools, `fstab/` and `queue-populator/`. Questions here cover
the *group*: why it exists as a separate layer, when to use the fan-out vs. the
child directly, and how the two tools relate. Each child has its own
`docs/PROJ-FAQ.md` for tool-specific why/when/caveat questions — see the
`Child FAQ Indexes` section at the bottom rather than expecting internals here.

## Motivation

### Why does this directory exist instead of just putting fstab and queue-populator straight under utilities/?

Because they're both macOS-host-only and share nothing with the rest of `utilities/`
(which is Linux/k8s-oriented, installs via `make install-utilities` → `~/.local/bin` +
`share/k8-lib`). Grouping them under `osx/` keeps that platform boundary visible in the
directory tree and gives them one shared fan-out `Makefile` for the four common verbs
(`build/test/install/clean`) without forcing either tool to adopt the other's install
mechanism. The grouping buys navigability, not shared code — see Comparison below for
what it does *not* unify.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md) for the fan-out mechanism and ecosystem-fit rationale.*

### Why is the fan-out just a Makefile instead of a real build tool or task runner?

Because there's nothing to orchestrate beyond "run this verb in each child dir if it
supports it." The shared `../mk/subdirs.mk` include is ~a few dozen lines: iterate
`SUBDIRS`, probe each child's `.PHONY` targets, skip what's absent, print a banner. A
task runner (Just, Task, etc.) would add a dependency and a second config format for a
problem this small already solves. If a third macOS tool joins the group and needs
real dependency ordering between build steps, that's the point to revisit.

## Fit

### When should I use the group Makefile instead of just cd-ing into the child?

Use the group Makefile only when you want the *same* verb (`build`, `test`, `install`,
`clean`) applied uniformly and don't care about child-specific targets. The moment you
need something like `fstab`'s `status`/`uninstall` or `queue-populator`'s debug-logging
targets, `cd` into the child — the group Makefile only forwards the five standard verbs
and has no path to child-only ones.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-run-a-target-against-just-one-child-from-the-group-root).*

### Is this the right place to look if I'm not on macOS?

No. Both children are macOS-host tools; `fstab` needs Darwin-specific mount tooling and
`queue-populator` needs Apple Speech + a Swift/Xcode toolchain. On Linux the group
Makefile still runs (it doesn't check the host), but each child either no-ops or prints
a "skipped on Linux" notice per target. A PipeWire-based Linux port of the
queue-populator audio-routing feature exists elsewhere in the repo — that's a separate,
unrelated implementation, not something this directory can build for you.

## Comparison

### How does fstab relate to queue-populator — do they interact?

They don't. No shared code, no shared config, no shared install path, no shared
runtime. They're grouped here purely because both are macOS-host utilities; one is a
root LaunchDaemon for boot-time volume mounting, the other a login-user LaunchAgent for
voice-memo capture. Pick one, the other, or both — installing/uninstalling one has zero
effect on the other.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-figure-out-which-tool-i-need) to decide which you need.*

### Why isn't there a group-level config file or shared install script?

Because there's nothing to share — each child owns its own install path (`fstab` →
`/usr/local/bin` + `/Library/LaunchDaemons` via `sudo make install`;
`queue-populator` → `/Applications` + a user LaunchAgent via `install.sh`) and its own
config format. A group config file would either duplicate child config (drift risk) or
sit unused. If you're looking for one, you likely want the child's own HOWTO instead.

## Caveats

### Does `make install` at the group root need root/sudo?

Only for `fstab`; the group fan-out does **not** elevate privileges on your behalf —
it just invokes each child's `install` target, and `fstab`'s target internally expects
to be run with sudo available. Running `make install` from `utilities/osx/` without
sudo cached will fail partway through fstab's step while queue-populator's completes
normally (or vice versa depending on child order) — check each child's own output
rather than assuming a single exit code tells the whole story.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-buildtestinstallclean-every-osx-utility-in-one-command) for the gotcha list.*

## Child FAQ Indexes

Full why/when/caveat treatment for each tool lives in its own FAQ — don't expect it
re-derived here:

- **fstab** — [fstab/docs/PROJ-FAQ.summary.md](../fstab/docs/PROJ-FAQ.summary.md)
- **queue-populator** — [queue-populator/docs/PROJ-FAQ.summary.md](../queue-populator/docs/PROJ-FAQ.summary.md)
