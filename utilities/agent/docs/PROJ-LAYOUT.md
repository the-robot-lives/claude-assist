# Project Layout — utilities/agent

`utilities/agent/` is a **grouping directory** inside the Noizu Infra monorepo: it collects
agent-centric DevOps utilities, each a self-contained sub-project with its own build tooling
and its own `docs/` (layout + architecture summaries). This document maps the grouping level
only — for internals, follow the per-child links below.

```
agent/
├── claude-assist/              # Agent-transcript indexer/browser (pnpm/TS monorepo: API + web + TUI)
│                               #   → [claude-assist/docs/PROJ-LAYOUT.summary.md](../claude-assist/docs/PROJ-LAYOUT.summary.md)
├── claude-desktop-sandbox/     # bwrap launcher for multiple isolated claude-desktop instances (bash)
│                               #   → [claude-desktop-sandbox/docs/PROJ-LAYOUT.summary.md](../claude-desktop-sandbox/docs/PROJ-LAYOUT.summary.md)
├── dangerously-safe/           # agent-sandbox: Rust TUI + Docker builder for sandboxed coding agents
│                               #   → [dangerously-safe/docs/PROJ-LAYOUT.summary.md](../dangerously-safe/docs/PROJ-LAYOUT.summary.md)
├── mallm/                      # LLM-friendly CLI documentation resolver (Node/TS CLI)
│                               #   → [mallm/docs/PROJ-LAYOUT.summary.md](../mallm/docs/PROJ-LAYOUT.summary.md)
├── media-tool/                 # Declarative YAML → media asset generation pipeline (Rust, 13 providers)
│                               #   → [media-tool/docs/PROJ-LAYOUT.summary.md](../media-tool/docs/PROJ-LAYOUT.summary.md)
├── run-claude/                 # Agent shim controller: directory-aware model routing via LiteLLM proxy (Python)
│                               #   → [run-claude/docs/PROJ-LAYOUT.summary.md](../run-claude/docs/PROJ-LAYOUT.summary.md)
├── skill-manage/               # Claude Code skill symlink/catalog manager (Rust CLI + ratatui TUI)
│                               #   → [skill-manage/docs/PROJ-LAYOUT.summary.md](../skill-manage/docs/PROJ-LAYOUT.summary.md)
├── docs/                       # This grouping-level documentation
│   ├── PROJ-LAYOUT.md          #   Main layout (this file)
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion summary
└── Makefile                    # Fan-out Makefile: delegates build/compile/test/install/clean to subdirs
```

## Children at a Glance

| Utility | Language / Stack | One-liner | Docs |
|---|---|---|---|
| `claude-assist` | TypeScript, pnpm workspaces | Index/search/extract AI coding-agent transcripts (REST + web SPA + TUI over SQLite FTS5/vec) | [layout](../claude-assist/docs/PROJ-LAYOUT.summary.md) · [arch](../claude-assist/docs/PROJ-ARCH.summary.md) |
| `claude-desktop-sandbox` | Bash + bwrap | Run multiple isolated claude-desktop instances, each with its own `$HOME` | [layout](../claude-desktop-sandbox/docs/PROJ-LAYOUT.summary.md) · [arch](../claude-desktop-sandbox/docs/PROJ-ARCH.summary.md) |
| `dangerously-safe` | Rust (+ legacy bash) | agent-sandbox: TUI-driven Docker image composer/runner for sandboxed coding agents | [layout](../dangerously-safe/docs/PROJ-LAYOUT.summary.md) · [arch](../dangerously-safe/docs/PROJ-ARCH.summary.md) |
| `mallm` | Node.js CLI | Structured, LLM-friendly docs for CLI tools via `.mallm/` → `~/.config/mallm/` → `--mallm` → `--help` resolution chain | [layout](../mallm/docs/PROJ-LAYOUT.summary.md) · [arch](../mallm/docs/PROJ-ARCH.summary.md) |
| `media-tool` | Rust (clap/tokio/ratatui) | Generate media assets from `.media.prompt` YAML with DAG ordering, multi-provider generation, LLM eval | [layout](../media-tool/docs/PROJ-LAYOUT.summary.md) · [arch](../media-tool/docs/PROJ-ARCH.summary.md) |
| `run-claude` | Python + LiteLLM | Directory-aware model routing: front proxy (:4443) → LiteLLM (:4444) with self-healing watchdog | [layout](../run-claude/docs/PROJ-LAYOUT.summary.md) · [arch](../run-claude/docs/PROJ-ARCH.summary.md) |
| `skill-manage` | Rust | Discover, symlink, catalog, and audit Claude Code skills | [layout](../skill-manage/docs/PROJ-LAYOUT.summary.md) · [arch](../skill-manage/docs/PROJ-ARCH.summary.md) |

## Makefile (fan-out)

The grouping `Makefile` sets `SUBDIRS` (all seven children) and includes `../mk/subdirs.mk`,
which forwards `build` / `compile` / `test` / `install` / `clean` to each child that declares
the target (with a `build` → `compile` fallback). No build logic lives at this level.

## Conventions

- Each child is self-contained: own README, Makefile, and `docs/PROJ-LAYOUT.summary.md` +
  `docs/PROJ-ARCH.summary.md` (some also carry full `layout/` / `arch/` detail dirs).
- Do not document child internals here — update the child's own docs and keep this map
  to one line + link per child.
