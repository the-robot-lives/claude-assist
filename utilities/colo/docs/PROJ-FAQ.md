# FAQ — utilities/colo

`utilities/colo` is a **grouping directory** (see [PROJ-ARCH](PROJ-ARCH.md) /
[PROJ-LAYOUT](PROJ-LAYOUT.md)): it has no runtime tools of its own, just a
delegating `Makefile` over child packages (today: `colo-utils`). This FAQ
covers group-level why/when/compared-to-what questions — installing across
the group, which tool covers a task, and how this directory relates to
sibling groups. **Tool-internal questions (why `colo-sync` instead of raw
`rsync`, is the deploy relay safe, etc.) live in
[colo-utils/docs/PROJ-FAQ.md](../colo-utils/docs/PROJ-FAQ.md) — not
duplicated here.**

## Motivation

### Why does this directory exist instead of just having `colo-utils` live directly under `utilities/`?

Because the group is designed to hold more than one colo-server-related
package over time, and a grouping directory gives them a single install
fan-out point without forcing them into one package. Today there's only one
child (`colo-utils`), so the indirection can look like pure overhead. The
payoff shows up the moment a second colo package is added: it registers in
one `SUBDIRS` line and inherits `install`/`build`/`test`/`clean` fan-out for
free, rather than every sibling utility group needing its own bespoke
Makefile logic.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-package-to-the-colo-group) to add a package.*

### Why is there a group-level `Makefile` at all if it has no targets of its own?

Because `make -C utilities/colo install` (or `build`/`test`/`clean`) needs
somewhere to fan out from before any second child package exists — the
delegator is infrastructure for a group, not a shortcut for the one member
it currently has. It costs one extra `make -C` hop today; it saves rewriting
the same fan-out logic when a second package lands.

## Fit

### When should I run `make -C utilities/colo install` instead of the repo root's `make install-utilities`?

Almost never on its own — reach for the group Makefile only when you
specifically want *just* the colo group's packages reinstalled (e.g. you
edited `colo-utils` and don't want to re-run installs for every other
utility group). For a normal fresh checkout or "get everything on PATH"
task, `make install-utilities` from the repo root is correct: it installs
`colo-*` **and** the sibling `cluster-*` tools (from
`utilities/k8/cluster-utils`) **and** `k8-lib` in one pass. The group
Makefile alone stops at `SUBDIRS := colo-utils` and never reaches
`cluster-utils`.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-every-colo-related-tool-from-this-group).*

### Is this the right place to add a new k8s dashboard tool (another `cluster-*`-style script)?

No, if it targets the cluster broadly — that family's canonical home is
`utilities/k8/cluster-utils/`, a separate sibling group, even though
`colo-utils/bin/` ships copies of those scripts for standalone use. Add here
only if the new tool is specifically about the **colo server** (deploy
relay, SSH tunnels, colo-side sync) rather than general cluster inspection.
When in doubt, check whether the tool needs `cluster-utils`' k8s API access
patterns (→ belongs there) or colo-server-side file/process concerns (→
belongs here).

## Comparison

### How is `utilities/colo` different from `utilities/k8/cluster-utils`?

`utilities/colo` groups tools that operate **on/from the colo server**
(deploy relay, SSH tunnel, mirrored sync); `utilities/k8/cluster-utils`
groups tools that **inspect the k8s cluster** (`cluster-status`,
`cluster-nodes`, etc.) from any machine with kubectl access. They overlap in
one place: `colo-utils/bin/` vendors copies of the `cluster-*` scripts so
colo-utils works standalone without a `cluster-utils` checkout, but
`cluster-utils` is the canonical source for that family's behavior and docs.
If you're asking "does this dashboard command belong to colo or to
cluster-utils," the answer is almost always cluster-utils; colo owns the
deploy/tunnel/sync side only.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-figure-out-which-tool-covers-a-colocluster-task).*

### How does adding a package here differ from adding one to `utilities/k8/cluster-utils` or another utility group?

Mechanically the same pattern (own `Makefile` with `install` in
`.PHONY`, own `docs/`, appended to the parent's `SUBDIRS`) — the difference
is purely which domain the package belongs to. There's no colo-specific
scaffolding requirement beyond what `utilities/mk/subdirs.mk` expects of any
child.

## Capability

### Can I install just one tool out of `colo-utils` without pulling in the rest of the group?

Not through this directory's tooling — `make -C utilities/colo install`
fans out at the *package* level (all of `colo-utils`), not per-binary. If
you need a single binary, either symlink it manually from
`colo-utils/bin/` or run `colo-utils`'s own `make install` and ignore the
binaries you don't need; there's no group-level or child-level flag to
install a subset.

## Caveats

### If I only run `make -C utilities/colo install`, will I have everything the colo tools need?

No — this only installs `colo-*` binaries; it does not install `k8-lib`,
which several `colo-*`/`cluster-*` scripts source guardedly and degrade
without. Missing `k8-lib` means those scripts still run but with reduced
functionality, not a hard failure, which can mask the gap until you hit the
degraded behavior. Use root `make install-utilities` if you want the
guarantee that `k8-lib` is present too.

### Will group-level docs here tell me how to use a specific `colo-*`/`cluster-*` command?

No, and that's intentional — this FAQ and its sibling HOWTO stop at "which
tool, which package, which install path." Flags, config, and per-command
behavior are documented only in
[colo-utils/docs/PROJ-FAQ.md](../colo-utils/docs/PROJ-FAQ.md) and
[colo-utils/docs/PROJ-HOWTO.md](../colo-utils/docs/PROJ-HOWTO.md) (or
`cluster-utils`'s equivalents for cluster-* internals). If you came here
looking for a specific command's behavior, follow the link — it won't be
repeated at this level, by design (see PROJ-ARCH's "Key Decisions").

## Trust

### If I add a package here, does it inherit any colo-specific security posture?

No — `subdirs.mk` fan-out has no security opinions of its own; whatever
hardening a child package needs (systemd sandboxing, SSH host-key policy,
etc.) is the child's own responsibility to implement and document. Group
membership only affects install/build wiring, not runtime trust boundaries.
