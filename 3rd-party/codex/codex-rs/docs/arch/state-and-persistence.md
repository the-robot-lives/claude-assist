# State & Persistence Architecture

Codex persists data at three levels: configuration (immutable per session), conversation history (recoverable and queryable), and runtime session state (transient). This separation enables thread resumption, inspection, and archival without requiring all runtime state to persist.

## Persistence Layers

### 1. Configuration (Immutable)

Configuration is loaded once at session startup and remains constant throughout the session:

**Sources** (in precedence order):
- Compiled-in defaults (binary)
- System config files (`/etc/codex`, platform-specific)
- User config files (`~/.config/codex/config.toml`, `~/.codex/config.toml`)
- Environment variables (runtime overrides)
- Cloud secrets (Infisical, AWS Secrets Manager, environment-specific)

**Validation & Schemas**:
- `config` crate generates JSON Schema for IDE integration
- Profiles (e.g., `dev`, `prod`) can be selected at startup
- Validation ensures all required fields are present and valid

**Access Pattern**: Read-only after session initialization. Core can safely assume config does not change mid-turn.

### 2. Conversation History (Persistent & Recoverable)

Thread and turn data is persisted to enable resume, fork, archive, and inspection workflows:

**Storage Backends**:

| Backend | Purpose | Format |
| ------- | ------- | ------ |
| **Rollout Files** | Session snapshots and full conversation records | JSON (human-readable, portable) |
| **SQLite State DB** | Indexed thread/turn/item queries and metadata | SQL with schema migrations (Liquibase) |
| **Thread Store** | Thread index and lifecycle tracking | SQLite tables (part of state DB) |

**Rollout Model**:
- Single rollout file per thread contains complete conversation up to that point
- Rollout is written at turn boundaries (after model completes and items are persisted)
- Format: JSON lines (one item per line) for streaming and resumption

**SQLite State**:
- Tables: `threads`, `turns`, `items`, `metadata`, `thread_tags`, `rollout_index`
- Schema evolves via migrations (recorded in Liquibase changelog)
- Queries support: thread listing, turn history, item search, metadata filtering
- Partitioning: Database per thread or shared DB with thread_id foreign keys (depends on scale)

**Lifecycle**:
```
User starts turn
  ↓
Core streams items (model chunks, tool calls, outputs)
  ↓
Items are appended to SQLite in near-real-time
  ↓
Turn completes; turn record finalized
  ↓
Rollout file is written (snapshot up to current point)
  ↓
Next turn can resume from either DB or rollout file
```

### 3. Runtime Session State (Transient)

Session state is kept in memory and reconstructed on reconnect:

**Contents**:
- Model context cache (assembled prompts, parsed tokens)
- Current turn builder (accumulated messages and pending tool calls)
- Transport/connection state (WebSocket frames, stdio buffers)
- Plugin state (loaded skills, enabled hooks, MCP connections)
- File watcher state and diff caches

**Scope**: Single client session; lost on disconnect or process exit (intentional)

**Recovery**: On reconnect, client resumes from last persisted turn in DB/rollout. The next turn is a fresh context assembly.

## Data Structures

### Thread
```rust
pub struct Thread {
    pub id: Uuid,                       // Unique identifier
    pub config: ThreadConfig,           // Model, tools, plugins, approval rules
    pub created_at: DateTime,
    pub updated_at: DateTime,
    pub metadata: Map<String, Value>,   // User-provided tags, links, notes
    pub state: ThreadState,             // Active, archived, paused, etc.
}
```

### Turn
```rust
pub struct Turn {
    pub id: Uuid,
    pub thread_id: Uuid,
    pub sequence: u32,                  // Turn number (0, 1, 2, ...)
    pub started_at: DateTime,
    pub completed_at: Option<DateTime>,
    pub model: String,                  // Which model was used
    pub settings: TurnSettings,         // Temperature, max_tokens, etc.
    pub items: Vec<Item>,               // Streamed items in this turn
}
```

### Item
```rust
pub enum Item {
    UserMessage { content: String, metadata: Map },
    ModelReasoning { delta: String, complete: String },
    ModelCompletion { text: String },
    ToolCall { id: String, name: String, arguments: Value },
    ToolResult { id: String, content: String, error: Option<String> },
    SystemMessage { role: String, content: String },
    ApprovalRequest { tool: String, arguments: Value, approved: bool },
    CommandExecution { command: String, exit_code: i32, stdout: String, stderr: String },
}
```

## Query Patterns

**Common queries** (all supported via `state` crate):

```sql
-- Find all threads
SELECT id, created_at, metadata FROM threads ORDER BY updated_at DESC

-- Get turn history for a thread
SELECT id, sequence, started_at, completed_at, model FROM turns 
  WHERE thread_id = ? ORDER BY sequence

-- Get all items in a turn
SELECT type, content, metadata FROM items 
  WHERE turn_id = ? ORDER BY sequence

-- Find all tool calls in a thread
SELECT item_id, name, arguments FROM items 
  WHERE turn_id IN (SELECT id FROM turns WHERE thread_id = ?)
    AND type = 'ToolCall'

-- Get recent model responses
SELECT item_id, model, content FROM items 
  WHERE thread_id = ? AND type = 'ModelCompletion' 
  ORDER BY created_at DESC LIMIT 10
```

## Concurrency & Consistency

**Single-Writer, Multi-Reader Model**:
- Only the active `core` (processing a turn) writes to state
- Multiple readers (inspection tools, UI, background jobs) can read concurrently
- SQLite's WAL mode enables this without heavy locking

**Transaction Boundaries**:
- Each item append is a transaction
- Turn finalization is a transaction
- Rollout write is a transaction (idempotent)

**No Race Conditions**:
- A thread has only one active turn at a time (enforced by `core`)
- Concurrent reads don't block writes; writes don't block reads

## Rollout Files (Session Snapshots)

Rollout files are JSON-based snapshots of conversation state:

**Purpose**:
- Portable conversation archive (single file, all history)
- Resumption point (if SQLite is unavailable or corrupted)
- Version control and diff-friendly format
- Human-readable conversation records

**Format** (line-delimited JSON):
```json
{ "type": "thread", "id": "uuid", "config": {...}, "created_at": "..." }
{ "type": "turn", "id": "uuid", "sequence": 0, "started_at": "..." }
{ "type": "item", "turn_id": "uuid", "type": "UserMessage", "content": "Hello" }
{ "type": "item", "turn_id": "uuid", "type": "ModelCompletion", "text": "Hi there!" }
{ "type": "turn_finalized", "turn_id": "uuid", "completed_at": "..." }
...
```

**Resumption**:
```rust
// On thread resume:
1. Load latest rollout file if it exists
2. Parse items sequentially until EOF
3. Verify state matches SQLite (if both exist)
4. If conflict: SQLite is authoritative (rollout may be stale)
```

## Schema Migrations

Persistence schema evolves via Liquibase:

**Location**: `core/src/sql/liquibase/core_schema.xml` (main schema)

**Pattern**:
```xml
<changeset id="001-initial-threads" author="system">
  <createTable tableName="threads">
    <column name="id" type="uuid" constraints="primaryKey"/>
    <column name="created_at" type="timestamp" constraints="notNull"/>
    ...
  </createTable>
</changeset>
```

**Application**: Migrations run at session startup via `state::initialize()`.

## Performance Considerations

**Large Thread History**:
- Queries on threads with 1000+ turns stay fast due to indexed turn_id
- Item pagination: use `LIMIT N OFFSET M` or cursor-based iteration

**Concurrent Access**:
- SQLite with WAL mode handles concurrent reads during writes
- For large deployments, consider replication to read replicas (future)

**Rollout File Size**:
- Typical conversations: 100KB - 1MB per thread
- Large conversations (100+ turns): 5-10MB
- Compression: Can be gzipped for archival

## Backup & Disaster Recovery

**Automatic Backups**:
- Rollout files are naturally backed up (one per thread)
- SQLite state DB can be backed up via `VACUUM INTO` (copy-safe)

**Resumption from Backup**:
1. Restore SQLite database or rollout file
2. On next session, `core` loads state from DB
3. If DB is missing, fallback to rollout file parsing
4. If both exist, DB is authoritative

**Archival Workflow**:
1. Mark thread as archived in metadata
2. Write final rollout file
3. (Optional) Export to external storage (S3, backup service)
4. SQLite record can be deleted to free space

