import Foundation

/// The local store's schema.
///
/// **Why SQLite and not a JSON snapshot.** The macOS agent persists a single
/// `timely-state.json` that is decoded whole on launch and rewritten whole on
/// every mutation. That is defensible for a menu-bar app holding one user's
/// current week. It is the wrong shape here for four reasons:
///
/// 1. **Companions page a timeline.** "Show me last March, grouped by client"
///    is a range scan. Against a blob it is a full decode of every span the
///    workspace has ever recorded, on a phone, to render thirty rows.
/// 2. **Write amplification.** A running timer touches a span every tick. A
///    snapshot store rewrites the entire history to record that one row moved,
///    so cost grows with total data rather than with the edit. On a device with
///    a year of spans that is seconds of I/O and a visible battery cost.
/// 3. **Partial durability.** A pull page and the cursor advance must land
///    together or not at all. A blob rewrite gives all-or-nothing per *file*,
///    which is far coarser than needed and still loses the whole file to a
///    crash mid-write. A transaction gives it per *operation*.
/// 4. **Concurrent read during sync.** WAL lets the UI read the timeline while
///    the sync engine writes a page. With a blob, both contend on one file and
///    the UI stalls behind the network.
///
/// The cost is a C dependency and hand-written SQL, which is why the SQL lives
/// here in one auditable place rather than being generated at call sites.
///
/// **Why one `entities` table rather than nine.** Every synced type shares the
/// same seven envelope fields and the same access patterns — by id, by
/// revision, by time. Nine near-identical tables would mean nine copies of
/// upsert, tombstone, cursor and paging logic, and each copy is a place for the
/// LWW rule to drift. The typed body lives in a JSON `document` column; the
/// fields that are actually *queried* are promoted to real indexed columns.
/// Unknown fields from a newer server survive in the document, which the
/// contract's change rules require.
enum StoreSchema {

    /// Bumped whenever the DDL below changes. A store written by a newer build
    /// is refused rather than opened and silently misread.
    static let version = 1

    static let statements: [String] = [
        """
        CREATE TABLE IF NOT EXISTS meta (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
        """,

        // MARK: entities
        //
        // `range_start` / `range_end` are the promoted time columns. Their
        // meaning is per-kind (a span's start/end, a screenshot's captured_at, an
        // analysis's analyzed_at) and they are NULL for kinds that are not
        // time-ranged, such as clients. This is what makes a date-range timeline
        // query an index seek.
        //
        // `search_text` is a lowercased haystack of the row's human-visible
        // names, so a companion's filter box does not decode every document.
        """
        CREATE TABLE IF NOT EXISTS entities (
            kind            TEXT    NOT NULL,
            id              TEXT    NOT NULL,
            workspace_id    TEXT    NOT NULL,
            server_revision INTEGER NOT NULL DEFAULT 0,
            created_at      REAL    NOT NULL,
            updated_at      REAL    NOT NULL,
            deleted_at      REAL,
            range_start     REAL,
            range_end       REAL,
            parent_id       TEXT,
            search_text     TEXT    NOT NULL DEFAULT '',
            dirty           INTEGER NOT NULL DEFAULT 0,
            document        TEXT    NOT NULL,
            PRIMARY KEY (kind, id)
        )
        """,

        // The timeline query: one kind, one workspace, a date window, newest
        // first. `deleted_at` is in the index so the common "not tombstoned"
        // filter is satisfied without touching the table.
        """
        CREATE INDEX IF NOT EXISTS entities_timeline
            ON entities (kind, workspace_id, range_start DESC, deleted_at)
        """,

        // The pull cursor query and the "what changed" feed.
        """
        CREATE INDEX IF NOT EXISTS entities_revision
            ON entities (workspace_id, server_revision)
        """,

        // "Every screenshot for this span", "every analysis for this screenshot".
        """
        CREATE INDEX IF NOT EXISTS entities_parent
            ON entities (kind, parent_id)
        """,

        // Rows the server has never acknowledged, for the bootstrap push.
        """
        CREATE INDEX IF NOT EXISTS entities_dirty
            ON entities (workspace_id, dirty) WHERE dirty = 1
        """,

        // MARK: push queue
        //
        // `seq` is the ordering authority. It is an INTEGER PRIMARY KEY
        // AUTOINCREMENT so that a dequeued-then-failed mutation cannot be handed
        // a recycled rowid and jump the queue.
        //
        // `mutation_id` is UNIQUE: it is the server's idempotency key, and
        // enqueueing the same one twice is a bug that must fail loudly at the
        // point of insertion rather than produce a double-apply.
        """
        CREATE TABLE IF NOT EXISTS push_queue (
            seq           INTEGER PRIMARY KEY AUTOINCREMENT,
            mutation_id   TEXT    NOT NULL UNIQUE,
            workspace_id  TEXT    NOT NULL,
            entity_kind   TEXT    NOT NULL,
            entity_id     TEXT    NOT NULL,
            operation     TEXT    NOT NULL,
            base_revision INTEGER,
            payload       TEXT    NOT NULL,
            created_at    REAL    NOT NULL,
            attempts      INTEGER NOT NULL DEFAULT 0,
            last_attempt  REAL,
            last_error    TEXT,
            batch_group   TEXT
        )
        """,

        """
        CREATE INDEX IF NOT EXISTS push_queue_order
            ON push_queue (workspace_id, seq)
        """,

        // "Does this row have an unanswered mutation?" — asked once per pulled
        // row to decide whether a local edit is still in flight (§7.1).
        """
        CREATE INDEX IF NOT EXISTS push_queue_entity
            ON push_queue (entity_kind, entity_id)
        """,

        // MARK: outcomes needing a human
        //
        // `suspected_duplicate` and `billing_overlap` land here. Nothing in this
        // package resolves them; they are surfaced and they wait. Auto-resolving
        // a billing overlap is inventing billable hours.
        """
        CREATE TABLE IF NOT EXISTS pending_outcomes (
            mutation_id  TEXT PRIMARY KEY,
            workspace_id TEXT    NOT NULL,
            entity_kind  TEXT    NOT NULL,
            entity_id    TEXT    NOT NULL,
            status       TEXT    NOT NULL,
            reason       TEXT,
            message      TEXT,
            recorded_at  REAL    NOT NULL,
            acknowledged INTEGER NOT NULL DEFAULT 0,
            detail       TEXT    NOT NULL
        )
        """,

        """
        CREATE INDEX IF NOT EXISTS pending_outcomes_open
            ON pending_outcomes (workspace_id, acknowledged, recorded_at DESC)
        """,

        // MARK: sync state
        //
        // One row per workspace. `cursor` is the only thing that decides what a
        // pull asks for, which is why it is written in the same transaction as
        // the page it describes.
        """
        CREATE TABLE IF NOT EXISTS sync_state (
            workspace_id               TEXT PRIMARY KEY,
            cursor                     INTEGER NOT NULL DEFAULT 0,
            tombstone_horizon_revision INTEGER NOT NULL DEFAULT 0,
            last_pull_at               REAL,
            last_push_at               REAL,
            last_server_time           REAL
        )
        """
    ]
}
