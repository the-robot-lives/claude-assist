# Storage Architecture

## Database

Single SQLite file at `~/.claude-assist/claude-assist.db` (configurable via `CLAUDE_ASSIST_DATA_DIR`).

### Pragmas

- `journal_mode = WAL` — concurrent readers with single writer
- `foreign_keys = ON` — referential integrity

### Extensions

- **sqlite-vec** — vector similarity search via virtual tables; stores 384-dim float32 embeddings

## Tables (Logical)

| Table | Purpose |
|-------|---------|
| conversations | Indexed conversation metadata (path, dates, title, tags, status) |
| messages | Individual messages with role, content, timestamp |
| message_embeddings | sqlite-vec virtual table for semantic search vectors |
| thread_edits | Edited conversation threads (injected/collapsed messages) |
| datasets | Named dataset collections for fine-tuning |
| dataset_entries | Individual training examples linked to conversations |
| prompts | Saved/extracted prompts with tags and evals |
| projects | Project metadata derived from conversation paths |

## Content Hashing

Files are hashed on index to skip re-processing unchanged conversations. Only new or modified JSONL files trigger re-indexing.

## Configuration

| Env Variable | Default | Purpose |
|-------------|---------|---------|
| `CLAUDE_ASSIST_DATA_DIR` | `~/.claude-assist` | Database and data directory |
| `CLAUDE_ASSIST_WATCH_PATHS` | `~/.claude/projects` | Colon-separated JSONL source paths |
| `CLAUDE_ASSIST_WATCH` | `true` | Enable/disable file watching |
| `PORT` | `3100` | API server port |
