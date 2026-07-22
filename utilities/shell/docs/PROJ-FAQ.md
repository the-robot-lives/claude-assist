# PROJ-FAQ — utilities/shell

Group-level *why/when/compared-to-what* questions — the ones a skeptical
adopter forms before wiring several of these eleven tools together, or before
deciding this collection is even the right place for a new tool. Each child's
own FAQ (`{tool}/docs/PROJ-FAQ.md`) covers that tool's internals; this file
only covers cross-tool concerns. See [PROJ-ARCH.md](PROJ-ARCH.md) for what the
group is and [PROJ-HOWTO.md](PROJ-HOWTO.md) for the procedures these answers
link to.

## Motivation

### Why is this eleven separate tools instead of one CLI with subcommands?

Because they don't share a runtime, and forcing one would cost more than it
buys. Each tool has an independent lifecycle (its own Makefile, tests, and
release cadence) and a language chosen for what it does — Bash for thin `gh`/
`git`/`zellij` wrappers, Rust where secret-handling, Unicode, locking, or a
TUI make correctness worth the extra weight. A single umbrella CLI would mean
every change recompiles/retests the whole surface and every tool inherits the
slowest one's build story. The trade-off is real: there's no shared version
number, and a few conventions (flag naming, `--dry-run` semantics) drift
slightly between tools rather than being enforced once.
→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions) for the full rationale.*

### Why do only two of these tools (`repo-lock`, `secret-bucket`) share a design contract, instead of all eleven?

Because that contract — value-free output, so an AI agent can operate on
secrets/locks without either ever appearing in a transcript — is expensive to
maintain and only matters where an agent's blast radius actually includes
credentials or file-editing races. Applying it to, say, `quick-gist` or
`remote-tunnel` would add ceremony for no benefit; those tools' natural output
(a gist URL, a tunnel PID) isn't sensitive. It's a targeted convention, not a
toolkit-wide one.

### Why bother with `zellij` + `tabbing-on` + `auto-sudo` together instead of a plain terminal or tmux?

Because the combination solves a specific agent-fleet problem plain tmux
doesn't: knowing at a glance which of several unattended agent tabs is doing
what, without the agent stalling on a password prompt it can't answer.
`zellij` gives the multi-tab session; `tabbing-on` keeps each tab's title
reflecting live status so you can scan a wall of tabs instead of clicking
into each one; `auto-sudo` lets pre-approved commands escalate without a TTY
prompt an unattended agent would hang on. Running a single agent in a plain
shell doesn't need any of this — it's a fleet-coordination setup, not a
general terminal upgrade.
→ *See [howto/agent-dev-workspace.md](howto/agent-dev-workspace.md).*

## Fit

### Should a new one-off script I wrote go in here, or somewhere else in the monorepo?

Here, if it's a developer-machine tool meant to end up on `PATH` via
`make install-utilities` and it doesn't read `.infra-config.yaml` or deploy
anything — that's this group's whole charter (see
[PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit)). If it deploys, provisions
infrastructure, or reads the build/deploy metadata layer, it belongs under
`terraform/` or as an image target in `.infra-config.yaml` instead, not here.
A script that's genuinely one-repo-specific (not reusable across projects)
usually belongs in that project's own `bin/` rather than this shared toolkit.

### I only need one of these eleven tools — do I have to install the whole group?

No. `make install-utilities` is the batch path; `make -C utilities/shell/<tool> install`
installs exactly one, with no dependency on the other ten (the sole optional
coupling is `tabbing-on`'s dc-mode wanting `direnv-config` on `PATH`, and that
mode is off by default).
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-every-tool-in-the-collection-in-one-shot).*

## Comparison

### I want a git/GitHub helper — how do I know which of the five git-adjacent tools to reach for?

There's a decision table for exactly this, because the overlap (`gcap` vs.
`submodule-commit` vs. `repo-lock exec` vs. `make-repo`) is the single most
common point of confusion in this group.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-pick-the-right-tool-for-a-gitgithub-task).*

### Why do both `direnv-config` and `secret-bucket` exist — doesn't one make the other redundant?

No — they sit at different trust levels on purpose. `direnv-config` (`dc`) is
the full read/write layered store, the thing that can decrypt and mutate
values. `secret-bucket` is a narrower, value-free surface (list/diff/copy,
never printing a value) meant for a lower-trust process or agent to operate
against without ever being handed decrypt access. Collapsing them would mean
either every caller gets full decrypt rights, or the full store loses features
to stay "safe" — neither is acceptable.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#non-obvious-capability-value-free-secret-auditing-for-agent-transcripts)
and each tool's own FAQ ([direnv-config](../direnv-config/docs/PROJ-FAQ.md),
[secret-bucket](../secret-bucket/docs/PROJ-FAQ.md)) for the deeper split.*

## Capability

### Can I run `repo-lock hook install` and `doc-pointers hook` (misc-git-utils) in the same repo without one clobbering the other?

Yes, but only in one install order — `doc-pointers hook` first, `repo-lock
hook install` last, because `repo-lock` chains an existing `pre-commit` while
`doc-pointers` overwrites it outright. Installed in the wrong order, one
tool's enforcement silently stops running with no error.
→ *See [howto/hook-install-order.md](howto/hook-install-order.md).*

### Can several agent sessions (Claude/Codex/human) actually share one checkout safely with these tools?

Yes, by pairing `repo-lock`'s lane locks + commit mutex with the plain git
tools (`gcap`/`gp` or `submodule-commit`) rather than committing directly —
but only once the hook is installed; taking a lock alone does not block a
racing session's bare `git commit`.
→ *See [howto/multi-agent-checkout.md](howto/multi-agent-checkout.md).*

## Caveats

### If I skip the pre-commit hook install step, do the lock/lane tools still protect me?

No, and this is the sharpest edge in the group: `repo-lock acquire` only
blocks *other sessions' `acquire` calls* on the same path — it does not stop
a plain `git commit` from another session that never called `acquire` at
all. The commit-time protection comes entirely from the installed
`pre-commit` hook. Skip the hook and the locking becomes an honor system.
→ *See [repo-lock's own FAQ](../repo-lock/docs/PROJ-FAQ.md) for the mechanics.*

### Is there any version pinning or compatibility matrix across these eleven tools?

No — each ships and versions independently, and nothing in the group enforces
that, say, `tabbing-on`'s dc-mode assumptions match the `direnv-config`
version currently on `PATH`. In practice this has only bitten the one soft
coupling (`tabbing-on` ↔ `direnv-config`); the other nine tools have zero
runtime dependency on each other, so drift elsewhere is cosmetic (flag
naming) rather than breaking.

### Isn't writing passwordless sudo entries for agent-run commands (`auto-sudo`) a security risk?

Yes, and it's an intentional, scoped trade-off rather than an oversight: the
sudoers file `auto-sudo sudoers write` generates grants NOPASSWD only to the
specific commands you list, not blanket root — the risk you're accepting is
that any process able to invoke those exact commands as your user (including
a compromised or misbehaving agent) can now run them as root without a
prompt. It exists because an unattended agent has no way to answer an
interactive password prompt, so without this an agent workflow needing
elevation simply hangs. Keep the command list narrow and audit
`/etc/sudoers.d/auto-sudo` after every regeneration; don't wildcard it.
→ *See [auto-sudo's passwordless-sudo guide](../auto-sudo/docs/howto/passwordless-sudo.md).*

## Trust

### Does anything in this group read or touch `.infra-config.yaml`, the cluster, or deploy-time secrets?

No child does, by design — these are developer-machine tools, decoupled from
the build/deploy metadata layer. `direnv-config` is the closest thing to an
exception: it stores the scalar config (`.envrc.k8.dc`) that `.infra-config.yaml`
tooling later reads, and `dc infisical` bridges into the Infisical/k8s-Secret
pipeline described in the repo-root [docs/secret-management.md](../../../docs/secret-management.md)
— but that push only happens when you explicitly run a sync command, never
as a side effect of installing or using the tool.
→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*
