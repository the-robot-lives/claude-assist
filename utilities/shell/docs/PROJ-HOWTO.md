# PROJ-HOWTO — utilities/shell

Task-oriented guides for the **group-level** questions: installing the whole
collection at once, picking the right tool for a job, and wiring multiple
tools together for cross-tool workflows (agent-fleet checkouts, secrets,
shared dev sessions). Each tool's own day-to-day usage lives in its own
`docs/PROJ-HOWTO.md` — follow the links below rather than expecting per-flag
detail here. For *what the group is* see [PROJ-ARCH.md](PROJ-ARCH.md); for
*where things live* see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install every tool in the collection in one shot

**Goal:** get all eleven tools' binaries/scripts on `PATH` from a fresh checkout.
**Prereqs:** repo cloned; `cargo`/`rustc` on `PATH` for the Rust-based tools
(`auto-sudo`, `direnv-config`, `repo-lock`, `secret-bucket`, `tabbing-on`).

1. From the repo root:
   ```bash
   make install-utilities
   ```
2. This recurses `utilities/Makefile` → `utilities/shell/Makefile`'s
   `SUBDIRS` list → each child's own install target via `../mk/subdirs.mk`.

**Verify:** `which dc repo-lock tabbing-status auto-sudo gcap zj-claude` all
resolve under `~/.local/bin` (or `~/bin` for `remote-tunnel`).

**Gotchas:**
- Installing one tool only: `make -C utilities/shell/<tool> install` — don't
  hand-roll `cargo install`/`cp`, per-tool Makefiles set up config dirs
  (`~/.config/<tool>/`) the binary expects.
- A tool silently missing from `PATH` after install usually means its
  Makefile has no `install` target match in `subdirs.mk` — check the child's
  own `docs/PROJ-HOWTO.md` first-hour guide for that tool's exact install
  step.

## How to: pick the right tool for a git/GitHub task

**Goal:** stop guessing between five git-adjacent tools in this collection.

| I want to... | Use | Not |
|---|---|---|
| Commit + push everything in *this* repo, one shot | `misc-git-utils`: `gcap "<msg>"` | `github-utils` (that's submodule-scoped) |
| Push my current branch, nothing else | `misc-git-utils`: `gp` | — |
| Commit + push every **dirty submodule**, nested included | `github-utils`: `submodule-commit` | `gcap` (single repo only) |
| Fast-forward every submodule to latest, no commits | `misc-git-utils`: `submodule-pull` | `submodule-commit` (that commits) |
| Review staged/unstaged/untracked diffs across nested submodules before committing | `misc-git-utils`: `submodule-diff` | — |
| Create/fork a new GitHub repo, set org/visibility | `make-repo` / `fork-repo` | — |
| Turn a directory into a gist | `quick-gist` | — |
| Claim a lane so another agent session doesn't stomp my edits, and serialize commits | `repo-lock acquire` + `repo-lock exec -- <commit cmd>` | — |
| Keep a Markdown link to a doc/code section resolving after the target moves | `misc-git-utils`: `doc-pointers` | — |

Each row links to the owning tool's own HOWTO for the full guide:
[github-utils](../github-utils/docs/PROJ-HOWTO.summary.md) ·
[make-repo](../make-repo/docs/PROJ-HOWTO.summary.md) ·
[misc-git-utils](../misc-git-utils/docs/PROJ-HOWTO.summary.md) ·
[quick-gist](../quick-gist/docs/PROJ-HOWTO.summary.md) ·
[repo-lock](../repo-lock/docs/PROJ-HOWTO.summary.md)

## How to: commit safely when several agent sessions share one checkout

Combine `repo-lock`'s lane locking + commit mutex with the plain git tools
(`gcap`/`gp`, or `github-utils`' `submodule-commit`) instead of committing
directly, so two sessions can't race on the same files or interleave commits.
→ *See [howto/multi-agent-checkout.md](howto/multi-agent-checkout.md)*

## How to: keep two hook-installing tools from clobbering each other

**Goal:** run both `repo-lock hook install` and `doc-pointers hook` in the
same checkout without one silently erasing the other's `pre-commit` hook.
→ *See [howto/hook-install-order.md](howto/hook-install-order.md)*

## How to: manage secrets across `.envrc*`, agent transcripts, and Infisical

`direnv-config` (`dc`) is the layered read/write store; `secret-bucket` is the
value-free list/diff/copy layer agents can use without ever seeing plaintext;
Infisical/k8s Secrets are the deploy-time destination. Full reference with
worked examples for all six common secret tasks: [docs/secret-management.md](../../../docs/secret-management.md)
(repo root — covers the pipeline these two tools feed).

- Day-to-day single value read/write, layering, rotation → [direnv-config HOWTO](../direnv-config/docs/PROJ-HOWTO.summary.md)
- Comparing/copying/setting secrets without printing values (agent-safe) → [secret-bucket HOWTO](../secret-bucket/docs/PROJ-HOWTO.summary.md)

## How to: stand up a multi-tab agent dev workspace

**Goal:** one `zellij` session, one tab per project directory, each tab
showing a live status title, with sudo-worthy commands auto-escalating and no
password prompt.
→ *See [howto/agent-dev-workspace.md](howto/agent-dev-workspace.md)*

## Non-obvious capability: value-free secret auditing for agent transcripts

Both `direnv-config` (`dc bat --flat`) and `secret-bucket` (`list`/`diff`) are
built so an AI agent can search, compare, and even copy/set secrets **without
the value ever appearing in the tool output or argv** — safe to run inside an
agent transcript. See each tool's HOWTO summary linked above for the specific
commands; this pairing is why both exist rather than one superseding the
other (`dc` owns the layered store, `secret-bucket` is the narrow
policy-gated surface a lower-trust process/user can be handed).

## Maintenance

- Adding a group-level guide here: keep it cross-tool — if the guide only
  concerns one child's internals, it belongs in that child's own
  `docs/PROJ-HOWTO.md` instead.
- Sync [PROJ-HOWTO.summary.md](PROJ-HOWTO.summary.md) whenever a guide is
  added, removed, or its Goal line changes.
