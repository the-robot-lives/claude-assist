# Project Layout — Summary (utilities/agent)

Grouping directory for agent-centric utilities; each child is a self-contained sub-project
with its own docs (see child `docs/PROJ-LAYOUT.summary.md`).

```
agent/
├── claude-assist/              # agent-transcript indexer/browser (pnpm/TS: API+web+TUI, SQLite)
├── claude-desktop-sandbox/     # bwrap multi-instance claude-desktop launcher (bash)
├── dangerously-safe/           # agent-sandbox: Rust TUI + Docker builder for sandboxed agents
├── mallm/                      # LLM-friendly CLI docs resolver (Node CLI)
├── media-tool/                 # YAML .media.prompt → media asset generation (Rust, 13 providers)
├── run-claude/                 # directory-aware model routing via LiteLLM proxy (Python)
├── skill-manage/               # Claude Code skill symlink/catalog manager (Rust)
├── docs/                       # grouping-level docs (PROJ-LAYOUT.md + this summary)
└── Makefile                    # fan-out to subdirs via ../mk/subdirs.mk
```
