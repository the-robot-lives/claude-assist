# NOIZU-CLI-1: Claude Assist

**Package:** `claude-assist` (npm — Linux, macOS, Windows)
**Category:** Dev Tools
**Status:** Design phase

## Elevator Pitch

A local dev tool for searching, browsing, editing, and managing Claude Code conversations — then extracting reusable agents, skills, workflows, and fine-tuning datasets from them. Your conversations contain valuable reasoning and solutions that disappear into JSONL archives. This tool makes them searchable, browsable, editable, and reusable.

## Problem

Claude Code conversations contain valuable reasoning, approaches, and solutions that disappear into JSONL archives after the session ends. Finding "that conversation where I solved X" means grepping raw JSON. Reusing a good approach means copy-pasting from terminal history. There's no way to:

- Search conversations by meaning, not just string match
- Browse and compare threads visually
- Edit, simplify, or curate conversation threads
- Extract a proven pattern into a reusable agent or skill
- Tag message sequences as fine-tuning data
- Merge insights from multiple conversations into one artifact
- Reorganize conversations across projects

## Solution

A CLI + local React web app, both backed by a shared TypeScript API server. The CLI is built with Ink (React for terminals) for rich interactive UIs. The web UI handles browsing, visual diffs, and curation workflows. Everything runs locally — no cloud dependency for core features.

## Architecture

```
claude-assist/
├── packages/
│   ├── api/              # TypeScript API server (Hono on Bun)
│   │   ├── src/
│   │   │   ├── routes/       # REST endpoints
│   │   │   ├── services/     # Business logic
│   │   │   ├── indexer/      # Conversation parser + index builder
│   │   │   ├── search/       # String (FTS5) + semantic (sqlite-vec) search
│   │   │   ├── transforms/   # Conversation → agent/skill/dataset converters
│   │   │   └── storage/      # SQLite for index + vectors, fs for conversations
│   │   └── index.ts
│   ├── cli/              # Interactive CLI (Ink — React for terminals)
│   │   ├── src/
│   │   │   ├── commands/     # search, list, show, edit, convert, rehome, merge, dataset
│   │   │   ├── components/   # Ink React components (thread viewer, search UI, wizards)
│   │   │   └── app.tsx       # Root Ink app with routing
│   │   └── bin.ts
│   ├── web/              # React frontend (Vite)
│   │   ├── src/
│   │   │   ├── pages/        # Search, Browse, Thread, Edit, Convert, Merge, Dataset
│   │   │   ├── components/   # Thread viewer, diff panel, search bar, dataset tagger
│   │   │   └── hooks/        # API client hooks
│   │   └── index.html
│   └── shared/           # Shared types + utilities
│       ├── types/            # Conversation, Message, Agent, Skill, DatasetEntry types
│       └── parsers/          # JSONL parser, markdown extractor
├── package.json          # Workspace root (pnpm workspaces)
└── tsconfig.base.json
```

### Data Flow

```
~/.claude/projects/*/   ──┐
                          │
                          ├──→  Indexer  ──→  SQLite (FTS5 + sqlite-vec)  ──→  API  ──→  CLI (Ink)
                          │                                                    │
                          │                                                    └──→  Web UI (Vite)
                          │
                          └──→  (raw JSONL read on demand for full thread content)
```

## Core Features

### Search
- **Full-text search** — SQLite FTS5 (inverted index) across all indexed conversations, with project/date filters
- **Semantic search** — sqlite-vec vectors from local CPU embeddings or hosted APIs, search by meaning ("how did I set up auth middleware?")
- **Scoped search** — limit to a project, date range, or conversation role (user/assistant/tool)

### Browse
- **Thread list** — all conversations grouped by project, sortable by date/length/relevance
- **Thread viewer** — rendered conversation with tool calls, code blocks, collapsible sections
- **Thread timeline** — visual timeline of a conversation showing decision points and direction changes

### Thread Edit/Revise
- **Collapse** — merge multiple messages into a single summary message
- **Simplify** — rewrite verbose exchanges into concise versions (LLM-assisted)
- **Remove** — delete noise messages (failed tool calls, retries, tangents)
- **Reorder** — rearrange messages to improve narrative flow
- **Inject** — add new messages (annotations, corrections, context)
- **Fork** — create an edited copy while preserving the original

Edits produce a new curated thread, never modify the source JSONL. This is the foundation for both the convert and dataset features.

### Dataset Tagging (for fine-tuning)
- **Tag sequences** — select a range of messages and tag them as a fine-tuning entry
- **Role mapping** — map conversation roles to system/user/assistant format
- **Quality labels** — mark entries as gold/silver/bronze for dataset curation
- **Export formats** — JSONL compatible with OpenAI, Anthropic, and open-source fine-tuning pipelines
- **Dataset management** — name, version, and track datasets across conversations
- **Bulk operations** — tag similar patterns across multiple threads

The edit/revise workflow feeds directly into dataset tagging: clean up a thread, then tag the polished version as training data.

### Operations
- **Rehome** — move/copy a conversation to a different project scope
- **Clone** — duplicate a thread as a starting point for a new exploration
- **Revise** — edit a conversation's metadata (title, tags, summary)
- **Merge** — combine related threads into a single reference document
- **Archive** — mark threads as archived without deleting

### Convert
- **To Agent** — extract a conversation pattern into a `.claude/agents/*.md` definition
- **To Skill** — extract a reusable workflow into a skill definition
- **To Command** — extract a slash command from a conversation
- **To Snippet** — extract a code pattern with context into a reusable snippet
- **To Runbook** — compile multiple related conversations into a step-by-step guide

Conversion is interactive: the tool identifies candidate patterns, the user selects and refines, and the output is a ready-to-use file.

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Monorepo** | pnpm workspaces | Shared types, single install |
| **Runtime** | Bun (Node compatible) | Fast startup, built-in SQLite, TS-native |
| **API** | Hono on Bun | Lightweight, TypeScript-native, local server |
| **Storage** | SQLite (Bun built-in) | Zero-config, local-first |
| **Full-text search** | SQLite FTS5 | Built-in inverted index — `WHERE content MATCH 'query'` with ranked results, no external deps |
| **Vector search** | sqlite-vec | Pure C SQLite extension, ~100KB, brute-force KNN via virtual tables, works everywhere |
| **Embeddings (local)** | `@huggingface/transformers` + all-MiniLM-L6-v2 | ONNX via WASM, ~25MB model (downloaded on first run), 10-50ms/embed on CPU, fully offline, Bun compatible |
| **Embeddings (hosted)** | OpenAI, Voyage, Anthropic, Groq | Optional alternative — better quality, requires API key, costs per token |
| **CLI** | Ink 7 (React for terminals) + @inkjs/ui | Same React model as the web UI, Flexbox layout, interactive components, used by Claude Code itself |
| **Web** | React + Vite | Vite = fast ESM dev server + Rollup production bundler |
| **Styling** | Tailwind | Rapid iteration on local tool UI |
| **Distribution** | npm package | Cross-platform (Linux/macOS/Windows), `npx claude-assist` or global install |

### Why These Choices

**Ink over Commander.js** — This isn't a fire-and-forget CLI. Thread browsing, edit wizards, and dataset tagging are interactive multi-step UIs. Ink renders React components to the terminal with Flexbox layout, hooks, and state management. It's what Claude Code and Gemini CLI use. Startup is ~200-400ms (acceptable for interactive use; `bun build --compile` eliminates this entirely).

**sqlite-vec over sqlite-vss** — sqlite-vss is deprecated. sqlite-vec is its successor: pure C, no dependencies, ~100KB, works on every platform SQLite runs on (including WASM). Brute-force KNN is fast enough for conversation-scale data (thousands, not millions of vectors).

**`@huggingface/transformers` for local embeddings** — Every Node.js embedding library either wraps this or wraps the same ONNX runtime underneath. Alternatives researched: `fastembed` (Bun compat issues with onnxruntime-node), `embrix` (thin wrapper around the same engine), `onnxruntime-node` direct (boilerplate heavy). Transformers.js runs via WASM in Bun, downloads the ONNX model on first run (~25MB for MiniLM), then works fully offline. One-line API:
```ts
const pipe = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
const vec = await pipe('search text', { pooling: 'mean', normalize: true });
```
Upgrade path: swap to `nomic-embed-text-v1.5` (768d) for better quality with no architecture changes.

**FTS5** — SQLite's built-in full-text search extension. Creates a virtual table with an inverted index for fast ranked text search. No external search engine needed.

**Vite** — Frontend build tool by Evan You. Dev mode serves ES modules directly with hot module replacement (instant updates). Production mode bundles with Rollup. Much faster than Webpack for both dev and build.

## Data Model

### Conversation Source (JSONL Schema)

Conversations are JSONL files stored at `~/.claude/projects/{encoded-path}/{session-id}.jsonl`. The directory name is the project's absolute path with `/` replaced by `-`. Each line is a JSON object. There is no wrapper — the file is a flat sequence of heterogeneous records linked by `parentUuid` → `uuid` chains.

#### Common Fields (most record types)

| Field | Type | Description |
|-------|------|-------------|
| `uuid` | string | Unique ID for this record |
| `parentUuid` | string \| null | UUID of the preceding record (null for first user message) |
| `type` | string | Record type (see below) |
| `timestamp` | ISO 8601 | When this record was created |
| `sessionId` | string | Conversation/session UUID (matches filename) |
| `isSidechain` | boolean | Whether this is a branched/sidechain message |
| `userType` | string | `"external"` for normal use |
| `entrypoint` | string | `"cli"`, `"web"`, etc. |
| `cwd` | string | Working directory at time of message |
| `version` | string | Claude Code version (e.g. `"2.1.114"`) |
| `gitBranch` | string | Active git branch |

#### Record Types

**`permission-mode`** — First line of the file. Sets the session's permission mode.
```json
{ "type": "permission-mode", "permissionMode": "auto", "sessionId": "..." }
```

**`user`** — User message. Content is either a string or array of content blocks.
```json
{
  "type": "user",
  "promptId": "...",
  "message": { "role": "user", "content": "the user's message" },
  "uuid": "...", "parentUuid": null, "timestamp": "...",
  "permissionMode": "auto",
  "cwd": "/path/to/project", "sessionId": "...", "version": "...", "gitBranch": "main"
}
```

**`user` (tool result)** — Tool results are delivered as user messages with `tool_result` content blocks.
```json
{
  "type": "user",
  "message": {
    "role": "user",
    "content": [{
      "type": "tool_result",
      "tool_use_id": "toolu_...",
      "content": "command output here",
      "is_error": false
    }]
  },
  "toolUseResult": {
    "stdout": "...", "stderr": "", "interrupted": false, "isImage": false
  },
  "sourceToolAssistantUUID": "..."
}
```

**`assistant`** — Model response. Content is an array of typed blocks. Three content block variants:

*Thinking block:*
```json
{
  "type": "assistant",
  "message": {
    "model": "claude-opus-4-7",
    "role": "assistant",
    "content": [{ "type": "thinking", "thinking": "...", "signature": "..." }],
    "stop_reason": null,
    "usage": { "input_tokens": 5, "output_tokens": 8, "cache_creation_input_tokens": 23064, "cache_read_input_tokens": 17345, ... }
  }
}
```

*Text block (may have `model: "<synthetic>"` for harness-injected messages):*
```json
{
  "type": "assistant",
  "message": {
    "model": "<synthetic>",
    "role": "assistant",
    "content": [{ "type": "text", "text": "response text here" }],
    "stop_reason": "stop_sequence"
  }
}
```

*Tool use block:*
```json
{
  "type": "assistant",
  "message": {
    "model": "claude-opus-4-7",
    "role": "assistant",
    "content": [{
      "type": "tool_use",
      "id": "toolu_...",
      "name": "Bash",
      "input": { "command": "ls", "description": "List files" },
      "caller": { "type": "direct" }
    }],
    "stop_reason": "tool_use"
  }
}
```

**`attachment`** — System-injected context. Has an `attachment` object with a `type` field:
- `deferred_tools_delta` — available tool names added/removed
- `mcp_instructions_delta` — MCP server instructions
- `skill_listing` — available slash commands
- `auto_mode` — auto-permission reminder
- `queued_command` — queued user input
- `task_reminder` — task list reminder

**`system`** — System metadata. Has a `subtype` field:
- `turn_duration` — marks end of a turn with `durationMs` and `messageCount`
- `local_command` — local command execution
- `away_summary` — summary generated when conversation is compressed

**`file-history-snapshot`** — File state tracking for undo. Contains `trackedFileBackups` map.
```json
{ "type": "file-history-snapshot", "messageId": "...", "snapshot": { "trackedFileBackups": {}, "timestamp": "..." } }
```

**`last-prompt`** — Stores the last user prompt text for session resume.
```json
{ "type": "last-prompt", "lastPrompt": "truncated prompt text...", "sessionId": "..." }
```

**`queue-operation`** — Records queued user input (typed while model was responding).
```json
{ "type": "queue-operation", "operation": "enqueue", "content": "queued message", "timestamp": "..." }
```

#### Conversation Threading

Messages form a linked list via `parentUuid` → `uuid`. The first user message has `parentUuid: null`. A single assistant turn may span multiple JSONL lines (thinking → text → tool_use), each linking to the previous. Tool results link back to the assistant message that requested them via `sourceToolAssistantUUID`.

#### Key Indexing Notes

- **Session ID** = filename stem = `sessionId` field on every record
- **Project path** = directory name, decode by replacing leading `-` with `/` and internal `-` with `/`
- **Conversation content** lives in `type: "user"` and `type: "assistant"` records; other types are metadata
- **Token usage** is on assistant messages at `message.usage`
- **Model used** is at `message.model` (ignore `<synthetic>` — those are harness-injected)
- **`isSidechain: true`** marks branched/alternate responses — may want to filter or flag these

### Index Database (SQLite)

```sql
-- Core conversation metadata
conversations (
  id            TEXT PRIMARY KEY,   -- hash of file path + first message timestamp
  project_path  TEXT,               -- which project this belongs to
  started_at    DATETIME,
  updated_at    DATETIME,
  message_count INTEGER,
  title         TEXT,               -- auto-generated or user-assigned
  summary       TEXT,               -- LLM-generated summary
  tags          TEXT,               -- JSON array
  status        TEXT,               -- active | archived | edited
  source_path   TEXT                -- path to source JSONL
);

-- Full-text search (FTS5 virtual table)
messages_fts (
  conversation_id  TEXT,
  role             TEXT,
  content          TEXT,
  timestamp        DATETIME
);

-- Vector embeddings (sqlite-vec virtual table)
conversation_vectors (
  id        TEXT,                   -- conversation_id
  embedding FLOAT[384]             -- MiniLM-L6-v2 output (or 768 for nomic)
);

-- Edited thread versions
thread_edits (
  id                TEXT PRIMARY KEY,
  source_id         TEXT,           -- original conversation_id
  created_at        DATETIME,
  description       TEXT,           -- what was changed
  messages          TEXT            -- JSON array of edited message sequence
);

-- Fine-tuning dataset entries
dataset_entries (
  id                TEXT PRIMARY KEY,
  dataset_name      TEXT,
  conversation_id   TEXT,           -- source conversation
  edit_id           TEXT,           -- optional: from an edited version
  start_index       INTEGER,        -- first message in range
  end_index         INTEGER,        -- last message in range
  quality           TEXT,           -- gold | silver | bronze
  system_prompt     TEXT,           -- optional system message
  messages          TEXT,           -- JSON array: [{role, content}, ...]
  created_at        DATETIME
);

-- Dataset metadata
datasets (
  name        TEXT PRIMARY KEY,
  description TEXT,
  version     INTEGER DEFAULT 1,
  created_at  DATETIME,
  updated_at  DATETIME,
  entry_count INTEGER DEFAULT 0
);
```

## CLI Interface

```bash
# Search
claude-assist search "auth middleware"              # full-text search
claude-assist search --semantic "how to set up JWT" # semantic search
claude-assist search --project aifighter.com        # scoped to project

# Browse
claude-assist list                                  # recent conversations
claude-assist list --project codefre.sh             # by project
claude-assist show <id>                             # render a thread (interactive Ink viewer)

# Edit
claude-assist edit <id>                             # interactive thread editor
claude-assist edit <id> --collapse 3-7              # collapse messages 3-7 into summary
claude-assist edit <id> --remove 5,8,12             # remove specific messages
claude-assist edit <id> --simplify                  # LLM-assisted simplification

# Operations
claude-assist rehome <id> --to aifighter.com        # move to project
claude-assist clone <id>                            # duplicate thread
claude-assist tag <id> auth,middleware              # add tags
claude-assist merge <id1> <id2> --output merged.md  # combine threads
claude-assist archive <id>                          # archive

# Convert
claude-assist convert <id> --to agent               # extract agent definition
claude-assist convert <id> --to skill               # extract skill
claude-assist convert <id> --to command              # extract slash command
claude-assist convert <id> --to runbook              # compile runbook

# Dataset
claude-assist dataset create my-finetune            # create a named dataset
claude-assist dataset tag <id> --range 5-12         # tag message range as training entry
claude-assist dataset tag <id> --quality gold       # set quality label
claude-assist dataset list                          # list all datasets
claude-assist dataset export my-finetune            # export as JSONL
claude-assist dataset export my-finetune --format openai    # OpenAI format
claude-assist dataset export my-finetune --format anthropic # Anthropic format

# Server
claude-assist serve                                 # start API + web UI
claude-assist index                                 # rebuild search index
claude-assist index --watch                         # watch for new conversations
```

## Web UI Pages

| Page | Purpose |
|------|---------|
| **Dashboard** | Recent conversations, search bar, quick stats |
| **Search** | Full search with filters (text + semantic), results with highlighted matches |
| **Browse** | Project-grouped thread list, sortable/filterable |
| **Thread** | Full conversation viewer with collapsible tool calls |
| **Edit** | Interactive thread editor: collapse, simplify, remove, reorder, inject messages |
| **Convert** | Interactive wizard: select pattern, preview output, export to agent/skill/command |
| **Merge** | Side-by-side thread comparison, drag-and-drop section assembly |
| **Dataset** | Tag message sequences, manage datasets, preview training entries, export |
| **Settings** | Index paths, embedding provider (local vs hosted), model selection |

## Design Direction

**Style:** Nocturne + Minimal Tech (80/20 mix)
- Dark-native UI — this is a dev tool, matches terminal context
- Monospace where appropriate, clean sans-serif for UI chrome
- Accent color for search highlights and interactive elements
- Dense information layout — this is a power-user tool, not a marketing site
- Shared component language between Ink CLI and web UI where possible

## Embedding Provider Options

| Provider | Type | Model | Dims | Cost | Latency | Offline |
|----------|------|-------|------|------|---------|---------|
| **Transformers.js** | Local CPU | all-MiniLM-L6-v2 | 384 | Free | ~10-50ms | Yes |
| **Transformers.js** | Local CPU | nomic-embed-text-v1.5 | 768 | Free | ~50-100ms | Yes |
| **OpenAI** | Hosted | text-embedding-3-small | 1536 | ~$0.02/1M tokens | ~100-300ms | No |
| **Voyage** | Hosted | voyage-3 | 1024 | ~$0.12/1M tokens | ~100-300ms | No |
| **Anthropic** | Hosted | (when available) | — | TBD | TBD | No |
| **Groq** | Hosted | (embedding models) | — | TBD | TBD | No |

Default: local Transformers.js with MiniLM. Hosted providers configurable via `claude-assist config set embedding.provider openai`.

## Project Structure

```
claude-assist/
├── README.md                   # This file — full project spec
├── package.json                # pnpm workspace root
├── pnpm-workspace.yaml         # Workspace config
├── tsconfig.base.json          # Shared TypeScript config
├── .gitignore
├── design/                     # Design artifacts
│   ├── README.md               # Design status and next steps
│   ├── SITEMAP.md              # Information architecture (10 web UI pages)
│   ├── style-guide.md          # Nocturne + Minimal Tech visual system
│   ├── mockup-dashboard.svg    # Dashboard page mockup
│   ├── mockup-thread-viewer.svg # Thread Viewer page mockup
│   ├── mockup-search.svg       # Search page mockup
│   └── logos/                  # 6 SVG variants + preview.html
├── packages/
│   ├── shared/                 # @claude-assist/shared — types + parsers
│   │   └── src/
│   │       ├── types/          # Domain types (Conversation, SearchResult, Dataset, etc.)
│   │       └── parsers/        # JSONL parser + type guards
│   ├── api/                    # @claude-assist/api — Hono on Bun
│   │   └── src/
│   │       ├── routes/         # conversations, search, datasets, config, index
│   │       └── services/       # storage (SQLite), indexer, search
│   ├── cli/                    # @claude-assist/cli — Ink (React for terminals)
│   │   ├── bin.ts              # Entry point
│   │   └── src/
│   │       ├── app.tsx         # Root router
│   │       └── commands/       # search, list, show
│   └── web/                    # @claude-assist/web — React + Vite + Tailwind
│       ├── index.html
│       ├── tailwind.config.js  # Nocturne tokens as Tailwind theme
│       ├── vite.config.ts      # Dev server + API proxy
│       └── src/
│           ├── components/     # Layout (app shell with sidebar nav)
│           ├── pages/          # Dashboard, Search, Browse, Settings
│           └── hooks/          # API client
```

## Open Questions

- [x] ~~JSONL schema for Claude Code conversation storage~~ — documented above
- [x] ~~Design direction~~ — Nocturne + Minimal Tech (80/20), Plasma Cyan glow
- [x] ~~Information architecture~~ — 10 web UI pages documented in SITEMAP.md
- [x] ~~Monorepo scaffold~~ — pnpm workspaces with 4 packages (shared, api, cli, web)
- [ ] Bun's built-in SQLite vs better-sqlite3 — portability tradeoffs for sqlite-vec extension loading
- [ ] Thread edit UX — how much editing should happen in the CLI (Ink) vs pushing users to the web UI?
- [ ] LLM provider for simplify/summarize operations — use Claude API? Local model? User's configured provider?
- [ ] `bun build --compile` for single-binary distribution vs npm-only
