# PROJ-HOWTO.md — utilities/agent (grouping directory)

Task-oriented guides for **cross-tool** workflows in this grouping directory. Each child
tool has its own full `PROJ-HOWTO.md` for internals — this file only covers: installing
the group, deciding which child tool to reach for, and workflows that span more than one
child. See [PROJ-ARCH.md](PROJ-ARCH.md) for what each child is, [PROJ-LAYOUT.md](PROJ-LAYOUT.md)
for where things live.

## How to: install every agent utility in one shot

**Goal:** get `claude-assist`, `claude-sandbox`, `agent-sandbox`, `mallm`, `media-tool`,
`run-claude`, and `skill-manage` all on `PATH` without visiting each child.
**Prereqs:** repo checked out; per-tool build deps present (Rust toolchain, `pnpm`, `uv` —
see Gotchas).

1. From the repo root:
   ```bash
   make install-utilities
   ```
   Or scope to just this group:
   ```bash
   cd utilities/agent && make install
   ```
2. Both fan out via `../mk/subdirs.mk` to every child's own `install` target.

**Verify:**
```bash
which claude-assist claude-sandbox agent-sandbox mallm media-tool run-claude skill-manage
```
**Gotchas:**
- A child with a missing build dep (no `cargo`, no `pnpm`, no `uv`) fails its own `install`
  step and the fan-out prints `--- <dir> (install skipped: no target) ---` or a build
  error — it does **not** silently skip; check the tool-specific error against that
  child's own `docs/PROJ-HOWTO.md` first-hour guide.
- `media-tool` and `dangerously-safe`/`skill-manage` are Rust — first install compiles
  from source and is the slowest step; expect it to dominate wall-clock time.

## How to: pick the right tool for the job

**Goal:** decide which child tool to reach for without reading seven READMEs.

| I want to… | Use | Not |
|---|---|---|
| Get a disposable, sandboxed shell with an agent + a fresh worktree | `dangerously-safe` (`agent-sandbox`) | `claude-desktop-sandbox` (that's for the desktop GUI app) |
| Run an isolated instance of the **claude-desktop GUI app** (own login/session) | `claude-desktop-sandbox` (`claude-sandbox`) | `dangerously-safe` |
| Route a `claude`/agent CLI session's model traffic per-directory, or try non-Claude models | `run-claude` | — |
| Enable/disable skills, agents, or commands for a given harness (Claude Code, Codex, etc.) | `skill-manage` | hand-symlinking into `~/.claude/skills` |
| Search, browse, or edit past agent conversation transcripts | `claude-assist` | grepping JSONL by hand |
| Give an agent structured, LLM-friendly docs for one of your own CLI tools | `mallm` | relying on raw `--help` output |
| Generate an image/SVG/diagram/voice/video asset from a declarative prompt file | `media-tool` | ad hoc one-off provider API calls |

**Gotchas:**
- `dangerously-safe` and `claude-desktop-sandbox` sound similar (both "sandbox") but
  isolate different things: a **CLI agent + worktree** vs. a **GUI desktop app instance**.
- `run-claude` and `mallm` are both "LLM-adjacent" but solve unrelated problems: model
  routing/billing vs. CLI documentation for agents.

## How to: run a sandboxed session with routed model traffic

**Goal:** get an agent working in an isolated worktree (no host contamination) while its
model calls go through your chosen provider/profile instead of hitting Claude billing
directly.
**Prereqs:** both `agent-sandbox` (`dangerously-safe`) and `run-claude` installed; a
`run-claude` profile configured for the target directory (see
`run-claude/docs/PROJ-HOWTO.md` → "Configure a project directory for a specific provider").

1. Configure the project directory for the desired provider **before** entering the
   sandbox — `run-claude`'s directory routing is `cd`-based and keys off the host path:
   ```bash
   run-claude config set <project-dir> --profile <profile-name>
   ```
2. Launch the sandbox wizard from that same directory:
   ```bash
   agent-sandbox
   ```
3. Inside the sandboxed shell, run the agent as usual — its outbound model calls route
   through the front proxy your host `run-claude` set up for that directory.

**Verify:** inside the sandbox, `run-claude status` (or your profile's equivalent) shows
the expected provider active; agent output reflects the routed model, not the default.
**Gotchas:**
- If the sandbox mounts a **worktree copy** rather than the original path, `run-claude`'s
  directory-keyed routing may not match — route by the sandbox's mounted path, or set the
  profile as the container's global default instead of per-directory.
- `run-claude`'s proxy pair (front `:4443` / LiteLLM `:4444`) must already be reachable
  from inside the sandbox's network namespace; a fully offline sandbox (see
  `dangerously-safe` → "Allow the sandbox limited network access") needs an explicit
  allowance for those ports/host.

## How to: keep the same skill set enabled across every harness you use

**Goal:** use `skill-manage` once to control which `trl-*` skills/agents/commands are
symlinked into each provider's install root (Claude Code, Codex, etc.), instead of
re-enabling per-tool.
**Prereqs:** `skill-manage` installed; source trees registered (see its own
`PROJ-HOWTO.md` → "Point skill-manage at your source trees").

1. Bulk-enable a bundle by work type once:
   ```bash
   skill-manage bundle enable <bundle-name>
   ```
2. When you switch which harness you're driving a session through (e.g. plain Claude
   Code vs. a `run-claude`-routed session vs. inside a `dangerously-safe` sandbox), the
   symlinks skill-manage created are picked up automatically as long as that harness
   reads from the same provider install root — sandboxed environments that mount a
   **different** `$HOME` (see `claude-desktop-sandbox`) need their own `skill-manage`
   catalog or a shared source tree bind-mounted in.

**Gotchas:**
- `claude-desktop-sandbox` gives each sandbox its own `$HOME` — skills enabled on the
  host are **not** visible inside a sandbox unless you run `skill-manage` again inside it
  or bind-mount the shared skill source tree at sandbox creation.
- Full task list for skill-manage itself lives in its own
  `skill-manage/docs/PROJ-HOWTO.summary.md` — this guide only covers the cross-harness
  visibility gotcha.

## How to: make an agent-friendly reference for one of your own tools

**Goal:** so any agent (Claude Code, a `run-claude`-routed session, etc.) gets structured
when-to-use/how-to/gotcha docs for your CLI instead of parsing raw `--help`.
**Prereqs:** `mallm` installed.

1. Bootstrap a stub next to the tool:
   ```bash
   mallm init <tool-name>
   ```
2. Fill in usage/arguments/subcommands/context — full schema guide:
   `mallm/docs/howto/author-mallm-yaml.md`.
3. Validate before committing: `mallm validate <path-to-mallm.yaml>`.

**Verify:** `mallm docs <tool-name>` returns the structured entry.
**Gotchas:** see `mallm/docs/PROJ-HOWTO.md` — schema validation errors are the most common
first-run failure.

## Where to go for tool-specific tasks

Each child's full task index (steps, verify, gotchas) lives in its own
`<child>/docs/PROJ-HOWTO.summary.md` (task list) and `PROJ-HOWTO.md` (full guides):

- [claude-assist](../claude-assist/docs/PROJ-HOWTO.summary.md) — transcript search, edit,
  convert-to-skill, dataset export
- [claude-desktop-sandbox](../claude-desktop-sandbox/docs/PROJ-HOWTO.summary.md) —
  isolated claude-desktop instances, deep-link routing, GPU passthrough
- [dangerously-safe](../dangerously-safe/docs/PROJ-HOWTO.summary.md) — sandboxed
  agent-worktree wizard, custom apps, outbound traffic logging
- [mallm](../mallm/docs/PROJ-HOWTO.summary.md) — CLI doc lookup, authoring, validation
- [media-tool](../media-tool/docs/PROJ-HOWTO.summary.md) — `.media.prompt` generation,
  quality-gated eval loops, FIM library
- [run-claude](../run-claude/docs/PROJ-HOWTO.summary.md) — directory routing, watchdog,
  secrets, `claude-plan` passthrough
- [skill-manage](../skill-manage/docs/PROJ-HOWTO.summary.md) — catalog discovery, bundle
  enable, forking a skill for local edits
