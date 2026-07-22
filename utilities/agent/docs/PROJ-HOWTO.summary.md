# PROJ-HOWTO.summary.md — utilities/agent (grouping directory)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full guides. Group-level tasks
only: cross-tool workflows and which-tool-when. Per-child task lists are linked at the
bottom of the full file.

- **Install every agent utility in one shot** — get all seven child tools on `PATH` via
  the root or group `make install`, without visiting each child.
- **Pick the right tool for the job** — decision table disambiguating similarly-named or
  similarly-themed tools (e.g. `dangerously-safe` vs `claude-desktop-sandbox`, `run-claude`
  vs `mallm`).
- **Run a sandboxed session with routed model traffic** — combine `dangerously-safe`'s
  isolated worktree wizard with `run-claude`'s directory-based model routing in one
  workflow.
- **Keep the same skill set enabled across every harness you use** — use `skill-manage`
  once, understand the gap when a sandbox (e.g. `claude-desktop-sandbox`) has its own
  `$HOME`.
- **Make an agent-friendly reference for one of your own tools** — bootstrap and validate
  a `mallm.yaml` so any agent gets structured docs instead of raw `--help`.
