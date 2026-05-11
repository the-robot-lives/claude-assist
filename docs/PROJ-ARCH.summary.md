# Architecture Summary

Local-first tool for indexing and searching Claude Code JSONL conversation logs. Three interfaces (REST API, browser SPA, terminal TUI) backed by a single SQLite database with FTS5 and sqlite-vec for full-text + semantic search.

## Components

- **API** (Hono) — IndexerService parses JSONL, StorageService persists to SQLite, EmbeddingService generates 384-dim vectors via all-MiniLM-L6-v2, SearchService queries FTS5 + cosine similarity
- **Web** (React + Vite + Tailwind) — SPA with dashboard, search, browse, thread viewer, editor, dataset manager, prompt library
- **CLI** (Ink) — TUI commands: search, list, show, index
- **Shared** — TypeScript types, JSONL parsers, API auto-launcher

## Key Decisions

- Local-first: SQLite + local embeddings, no external services
- JSONL as source of truth; database is a derived index
- Monorepo with pnpm workspaces for shared types
- Hono over Express; sqlite-vec over pgvector
