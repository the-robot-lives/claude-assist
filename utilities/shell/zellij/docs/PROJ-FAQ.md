# FAQ

Anticipated why/when/compared-to-what questions for `utilities/shell/zellij`.
For *how to* run something, see [PROJ-HOWTO.md](PROJ-HOWTO.md); for *what
this is*, see [PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use these scripts instead of just typing `zellij` commands myself?

Because the repeatable parts — picking directories, laying out claude/nvim/shell
panes, naming and truncating the session, queuing the agent command — are
exactly the parts that are tedious and error-prone to retype by hand every
time you start a coding session across one or more project directories. The
honest trade-off: for a single one-off pane in a session you already have
open, plain `zellij action new-pane` is less indirection than reaching for
one of these scripts.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-open-a-dev-session-for-one-or-more-project-directories).*

### Why prefill the agent command instead of just running it immediately?

So a human presses Enter before an AI coding agent starts, rather than the
session opening with agents already live and possibly acting. This is a
deliberate confirmation gate, not a UX afterthought — it costs one keystroke
per pane and buys a last look at the directory/command before the agent can
touch anything. Unknown shells (not zsh/bash) degrade to just printing the
command instead of queuing it, so the gate is best-effort, not guaranteed.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

### Why generate a temporary KDL layout instead of always using `layouts/claude-dev.kdl`?

Because the static layout can't know your tab count or per-tab working
directory in advance — those are only known at invocation time (which
directories you picked in `fzf`, or listed in a workspace YAML). The static
`claude-dev.kdl` is kept around specifically for the case where you don't
need that: one tab, no picker, plain `zellij -n claude-dev`.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-use-the-static-layout-directly-with-zellij-no-wrapper-script).*

### Why does the `fzf` picker start with every directory pre-selected instead of none?

Because the common case is "open a dev session across most or all of what's
in this parent directory," and toggling a few outliers *off* is fewer
keystrokes than toggling most of them *on* one at a time. The trade-off is
discoverability: the header text ("Tab=toggle off... all selected") is the
only cue this is opt-out rather than opt-in, and it's easy to misread on a
first run and launch tabs for directories you didn't mean to include —
check the picker state before hitting Enter.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-open-a-dev-session-for-one-or-more-project-directories).*

### Why isn't this wired into `share/k8-lib` like most other Noizu utilities?

Deliberately not: `k8-lib` pulls in the broader infra/cluster assumptions of
this monorepo, and these scripts have nothing to do with clusters — they're
local dev-session ergonomics. Staying self-contained (only `zellij`, `fzf`,
optional `yq`/`nvim`) means they still work on a laptop that has never seen
`.infra-config.yaml`.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*

## Fit

### When should I reach for `zj-tab`/`zj-panes` instead of `zj-claude`?

When you already have a session running and want to grow it, not start a new
one. `zj-tab` adds a whole new claude/nvim/shell tab for another project
(and will start a fresh session if you run it outside one); `zj-panes` instead
splits the *current* tab you're sitting in — and errors out if you're not
inside a zellij session at all, since there's nothing to split.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-dev-tab-or-floating-dev-server-pane-to-a-session-already-running).*

### When is the static `claude-dev.kdl` layout the better choice over the `zj-*` scripts?

When you want exactly one tab, aren't picking from a set of directories, and
don't want the command prefilled — `zellij -n claude-dev` opens claude/nvim/shell
with a bare, unfocused-command left pane you type into yourself. It has no
per-directory batching and no prefill, so it's the minimal path, not a
feature-complete alternative to `zj-claude`.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-use-the-static-layout-directly-with-zellij-no-wrapper-script).*

### When is `zj-spawn` the right tool instead of `zj-claude`/`zj-codex`?

When the task isn't a coding-agent session at all — bulk `git pull`, running
tests, `make watch` across many repos. `zj-spawn` runs an arbitrary command
(or opens an editor for a multi-line scratch script) per selected directory,
with no claude/nvim/shell pane shape and no agent-prefill logic.

→ *See [howto/bulk-command-fanout.md](howto/bulk-command-fanout.md).*

### Is a workspace YAML always better than the `fzf` picker?

No — it's better only when you reopen the *same* set of directories often
enough that re-picking in `fzf` each time is the annoying part. For a
one-off or exploratory session across directories that change run to run,
the interactive picker is less setup for the same result; `--workspace`
also pulls in a hard dependency (`yq`) the picker path doesn't need.

→ *See [howto/workspace-yaml.md](howto/workspace-yaml.md).*

## Comparison

### How does `zj-codex` differ from `zj-claude`?

Only in which agent command gets queued and the flag prefix (`--codex-args`/
`--codex-command`/`--codex-message` vs `--claude-*`) — the picker, layout
generation, session naming, and prefill mechanics are identical. There's no
`--cerebras`/`--zai` provider shorthand on the codex side; if you need a
non-default backend there, use `--codex-command` directly.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#core-components).*

### How does `--cerebras`/`--zai` differ from `--claude-command`?

`--cerebras`/`--zai` are shorthands that set the same underlying field
`--claude-command` does (`run-claude with cerebras-pro` / `run-claude with
zai-pro`) — they aren't a separate mechanism. Combine them and whichever is
parsed last on the command line silently wins; they don't compose, so treat
them as mutually exclusive rather than stackable.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-use-a-non-default-ai-provider-cerebras--zai).*

## Capability

### Can I use an AI provider other than Claude Code or Codex?

Yes, but only through `--claude-command`/`--codex-command` (or the
`--cerebras`/`--zai` shorthands for Claude) — the scripts don't have a
plugin model for arbitrary providers, they just queue whatever full command
string you give them. `run-claude with <provider>` is sibling Noizu tooling
on `PATH`, not part of this package.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-use-a-non-default-ai-provider-cerebras--zai).*

### Can I preview what would launch without actually opening a session?

Yes, on `zj-claude`, `zj-codex`, and `zj-tab` via `--dry-run` — it prints the
generated KDL and the resolved directory/session/claude-command summary with
no zellij session left behind. `zj-panes` has no `--dry-run` (it mutates
your current live tab, there's nothing to preview); `zj-spawn` always prints
its layout as part of the launch banner, so there's no way to see it without
also launching.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-preview-a-layout-before-it-opens-a-real-session).*

## Caveats

### What happens if I select zero directories in the `fzf` picker?

The script prints "No directories selected." and exits `0` — no session is
opened, but it's not treated as an error, so don't rely on a non-zero exit
code to detect it in a wrapping script; check the message or the absence of
the session instead.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-open-a-dev-session-for-one-or-more-project-directories).*

### Why is my session name truncated / suffixed with something I didn't ask for?

Zellij session names become Unix-socket path segments, and macOS caps socket
paths at 104 bytes, so names are truncated to 20 characters. If that
truncated (or your explicit `--session`) name collides with a running
session, an explicit name gets a random suffix and an auto-derived name gets
a timestamp suffix — either way the session still opens, just not under the
exact name you typed.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

### Is it safe to put secrets in a workspace YAML or a `zj-spawn` scratch command?

Treat both as no. Workspace YAML is a plain file you write to disk yourself,
so ordinary file-permission hygiene applies. More sharply: `zj-spawn`'s
editor-based scratch command file is written under `/tmp` and left in place
after the session launches with **no cleanup trap** (unlike the generated
KDL layout, which is removed on exit) — don't put anything sensitive in it.

→ *See [howto/bulk-command-fanout.md](howto/bulk-command-fanout.md).*

### Does a missing directory in my workspace YAML abort the whole launch?

No. A `directories:` entry that doesn't resolve is skipped with a
`Warning: directory does not exist, skipping: <path>` on stderr, and the run
continues with whatever did resolve. If every entry is bad you'll end up
launching a session with zero tabs rather than getting a hard failure — check
the warnings, not just the exit code.

→ *See [howto/workspace-yaml.md](howto/workspace-yaml.md).*

## Trust

### Does this package read or touch anything from the wider Noizu infra (cluster, `.infra-config.yaml`, secrets)?

No. It has no dependency on `share/k8-lib`, reads no `.infra-config.yaml`,
and touches no cluster — its only external inputs are `zellij`, `fzf`,
optionally `yq` (workspace YAML) and `nvim` (editor pane). It's pure local
developer ergonomics, installed by the same `make install-utilities` as the
rest of the utilities family but otherwise independent of it.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*
