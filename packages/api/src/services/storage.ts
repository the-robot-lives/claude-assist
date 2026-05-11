import Database from "better-sqlite3";
import type { Conversation, ThreadEdit, EditedMessage, Dataset, DatasetEntry, QualityLabel } from "@claude-assist/shared";
import { createHash } from "node:crypto";
import * as sqliteVec from "sqlite-vec";

export interface StoredMessage {
  conversationId: string;
  role: string;
  content: string;
  timestamp: string;
}

export interface IndexStatus {
  status: "idle" | "indexing";
  lastIndexed: string | null;
  conversationCount: number;
}

export class StorageService {
  private db: Database.Database | null = null;
  private dbPath: string;
  private _status: "idle" | "indexing" = "idle";
  private _lastIndexed: string | null = null;
  private _vecAvailable = false;

  constructor(dbPath: string = "claude-assist.db") {
    this.dbPath = dbPath;
  }

  getDb(): Database.Database {
    if (!this.db) throw new Error("StorageService not initialized — call initialize() first");
    return this.db;
  }

  async initialize(): Promise<void> {
    this.db = new Database(this.dbPath);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");

    this.db.exec(`
      CREATE TABLE IF NOT EXISTS conversations (
        id            TEXT PRIMARY KEY,
        project_path  TEXT NOT NULL,
        started_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        message_count INTEGER NOT NULL DEFAULT 0,
        title         TEXT NOT NULL DEFAULT '',
        summary       TEXT,
        tags          TEXT NOT NULL DEFAULT '[]',
        status        TEXT NOT NULL DEFAULT 'active',
        source_path   TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations(project_path);
      CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations(updated_at);
    `);

    this.db.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id TEXT NOT NULL,
        role          TEXT NOT NULL,
        content       TEXT NOT NULL,
        timestamp     TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      );

      CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
    `);

    this.db.exec(`
      CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
        content,
        content='messages',
        content_rowid='id'
      );
    `);

    // Triggers to keep FTS index in sync with messages table
    this.db.exec(`
      CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages BEGIN
        INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
      END;
      CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
        INSERT INTO messages_fts(messages_fts, rowid, content) VALUES('delete', old.id, old.content);
      END;
      CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
        INSERT INTO messages_fts(messages_fts, rowid, content) VALUES('delete', old.id, old.content);
        INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
      END;
    `);

    this.db.exec(`
      CREATE TABLE IF NOT EXISTS thread_edits (
        id          TEXT PRIMARY KEY,
        source_id   TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        messages    TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (source_id) REFERENCES conversations(id)
      );

      CREATE INDEX IF NOT EXISTS idx_edits_source ON thread_edits(source_id);
    `);

    this.db.exec(`
      CREATE TABLE IF NOT EXISTS datasets (
        name        TEXT PRIMARY KEY,
        description TEXT NOT NULL DEFAULT '',
        version     INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        entry_count INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS dataset_entries (
        id              TEXT PRIMARY KEY,
        dataset_name    TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        edit_id         TEXT,
        start_index     INTEGER NOT NULL,
        end_index       INTEGER NOT NULL,
        quality         TEXT NOT NULL DEFAULT 'silver',
        system_prompt   TEXT,
        messages        TEXT NOT NULL DEFAULT '[]',
        created_at      TEXT NOT NULL,
        FOREIGN KEY (dataset_name) REFERENCES datasets(name),
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      );

      CREATE INDEX IF NOT EXISTS idx_entries_dataset ON dataset_entries(dataset_name);
    `);

    this.initVectorTable();
  }

  private initVectorTable(): void {
    const db = this.getDb();
    try {
      sqliteVec.load(db);
      db.exec(`
        CREATE VIRTUAL TABLE IF NOT EXISTS conversation_vectors USING vec0(
          id TEXT PRIMARY KEY,
          embedding float[384]
        );
      `);
      this._vecAvailable = true;
    } catch (err) {
      console.warn(
        `sqlite-vec not available: ${err instanceof Error ? err.message : err}. Semantic search disabled.`,
      );
      this._vecAvailable = false;
    }
  }

  get vecAvailable(): boolean {
    return this._vecAvailable;
  }

  async upsertVector(conversationId: string, embedding: Float32Array): Promise<void> {
    if (!this._vecAvailable) return;
    const db = this.getDb();
    db.prepare(
      "INSERT OR REPLACE INTO conversation_vectors (id, embedding) VALUES (?, ?)",
    ).run(conversationId, Buffer.from(embedding.buffer));
  }

  async knnSearch(queryEmbedding: Float32Array, limit: number = 20): Promise<Array<{ id: string; distance: number }>> {
    if (!this._vecAvailable) return [];
    const db = this.getDb();
    const rows = db.prepare(`
      SELECT id, distance
      FROM conversation_vectors
      WHERE embedding MATCH ?
      ORDER BY distance
      LIMIT ?
    `).all(Buffer.from(queryEmbedding.buffer), limit) as Array<{ id: string; distance: number }>;
    return rows;
  }

  async getConversations(options?: {
    sort?: string;
    limit?: number;
    groupBy?: string;
    project?: string;
  }): Promise<Conversation[]> {
    const db = this.getDb();
    const sort = options?.sort ?? "updated_at";
    const limit = options?.limit ?? 20;

    const allowedSorts: Record<string, string> = {
      updated_at: "updated_at DESC",
      started_at: "started_at DESC",
      message_count: "message_count DESC",
      title: "title ASC",
    };
    const orderClause = allowedSorts[sort] ?? "updated_at DESC";

    let query = `SELECT * FROM conversations`;
    const params: unknown[] = [];

    if (options?.project) {
      query += ` WHERE project_path = ?`;
      params.push(options.project);
    }

    query += ` ORDER BY ${orderClause} LIMIT ?`;
    params.push(limit);

    const rows = db.prepare(query).all(...params) as ConversationRow[];
    return rows.map(rowToConversation);
  }

  async getConversationCount(project?: string): Promise<number> {
    const db = this.getDb();
    if (project) {
      const row = db.prepare("SELECT COUNT(*) as count FROM conversations WHERE project_path = ?").get(project) as { count: number };
      return row.count;
    }
    const row = db.prepare("SELECT COUNT(*) as count FROM conversations").get() as { count: number };
    return row.count;
  }

  async getConversation(id: string): Promise<Conversation | null> {
    const db = this.getDb();
    const row = db.prepare("SELECT * FROM conversations WHERE id = ?").get(id) as ConversationRow | undefined;
    return row ? rowToConversation(row) : null;
  }

  async upsertConversation(conv: {
    id: string;
    projectPath: string;
    startedAt: string;
    updatedAt: string;
    messageCount: number;
    title: string;
    summary?: string | null;
    tags?: string[];
    status?: string;
    sourcePath: string;
  }): Promise<void> {
    const db = this.getDb();
    db.prepare(`
      INSERT INTO conversations (id, project_path, started_at, updated_at, message_count, title, summary, tags, status, source_path)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        project_path = excluded.project_path,
        started_at = excluded.started_at,
        updated_at = excluded.updated_at,
        message_count = excluded.message_count,
        title = excluded.title,
        summary = excluded.summary,
        tags = excluded.tags,
        status = excluded.status,
        source_path = excluded.source_path
    `).run(
      conv.id,
      conv.projectPath,
      conv.startedAt,
      conv.updatedAt,
      conv.messageCount,
      conv.title,
      conv.summary ?? null,
      JSON.stringify(conv.tags ?? []),
      conv.status ?? "active",
      conv.sourcePath,
    );
  }

  async insertMessages(conversationId: string, messages: StoredMessage[]): Promise<void> {
    const db = this.getDb();
    db.prepare("DELETE FROM messages WHERE conversation_id = ?").run(conversationId);

    const insert = db.prepare(
      "INSERT INTO messages (conversation_id, role, content, timestamp) VALUES (?, ?, ?, ?)",
    );
    const batch = db.transaction((msgs: StoredMessage[]) => {
      for (const msg of msgs) {
        insert.run(msg.conversationId, msg.role, msg.content, msg.timestamp);
      }
    });
    batch(messages);
  }

  async getMessages(conversationId: string): Promise<StoredMessage[]> {
    const db = this.getDb();
    return db
      .prepare("SELECT conversation_id as conversationId, role, content, timestamp FROM messages WHERE conversation_id = ? ORDER BY id")
      .all(conversationId) as StoredMessage[];
  }

  async getStats(): Promise<{ conversationCount: number; projectCount: number; lastIndexed: string | null }> {
    const db = this.getDb();
    const convRow = db.prepare("SELECT COUNT(*) as count FROM conversations").get() as { count: number };
    const projRow = db.prepare("SELECT COUNT(DISTINCT project_path) as count FROM conversations").get() as { count: number };
    return {
      conversationCount: convRow.count,
      projectCount: projRow.count,
      lastIndexed: this._lastIndexed,
    };
  }

  setIndexStatus(status: "idle" | "indexing"): void {
    this._status = status;
    if (status === "idle") {
      this._lastIndexed = new Date().toISOString();
    }
  }

  getIndexStatus(): IndexStatus {
    return {
      status: this._status,
      lastIndexed: this._lastIndexed,
      conversationCount: this.db
        ? (this.db.prepare("SELECT COUNT(*) as count FROM conversations").get() as { count: number }).count
        : 0,
    };
  }

  // Dataset methods
  async createDataset(name: string, description: string): Promise<Dataset> {
    const db = this.getDb();
    const now = new Date().toISOString();
    db.prepare(
      "INSERT INTO datasets (name, description, created_at, updated_at) VALUES (?, ?, ?, ?)",
    ).run(name, description, now, now);
    return { name, description, version: 1, createdAt: new Date(now), updatedAt: new Date(now), entryCount: 0 };
  }

  async getDatasets(): Promise<Dataset[]> {
    const db = this.getDb();
    const rows = db.prepare("SELECT * FROM datasets ORDER BY updated_at DESC").all() as DatasetRow[];
    return rows.map(rowToDataset);
  }

  async getDataset(name: string): Promise<Dataset | null> {
    const db = this.getDb();
    const row = db.prepare("SELECT * FROM datasets WHERE name = ?").get(name) as DatasetRow | undefined;
    return row ? rowToDataset(row) : null;
  }

  async createDatasetEntry(entry: {
    datasetName: string;
    conversationId: string;
    editId?: string;
    startIndex: number;
    endIndex: number;
    quality: QualityLabel;
    systemPrompt?: string;
    messages: Array<{ role: string; content: string }>;
  }): Promise<DatasetEntry> {
    const db = this.getDb();
    const id = createHash("sha256").update(`${entry.datasetName}:${entry.conversationId}:${Date.now()}`).digest("hex").slice(0, 16);
    const now = new Date().toISOString();
    db.prepare(
      "INSERT INTO dataset_entries (id, dataset_name, conversation_id, edit_id, start_index, end_index, quality, system_prompt, messages, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ).run(id, entry.datasetName, entry.conversationId, entry.editId ?? null, entry.startIndex, entry.endIndex, entry.quality, entry.systemPrompt ?? null, JSON.stringify(entry.messages), now);

    db.prepare("UPDATE datasets SET entry_count = entry_count + 1, updated_at = ? WHERE name = ?").run(now, entry.datasetName);

    return { id, ...entry, createdAt: new Date(now) };
  }

  async getDatasetEntries(datasetName: string, filters?: { quality?: QualityLabel }): Promise<DatasetEntry[]> {
    const db = this.getDb();
    let query = "SELECT * FROM dataset_entries WHERE dataset_name = ?";
    const params: unknown[] = [datasetName];
    if (filters?.quality) {
      query += " AND quality = ?";
      params.push(filters.quality);
    }
    query += " ORDER BY created_at DESC";
    const rows = db.prepare(query).all(...params) as DatasetEntryRow[];
    return rows.map(rowToDatasetEntry);
  }

  async updateDatasetEntry(id: string, updates: { quality?: QualityLabel; systemPrompt?: string }): Promise<void> {
    const db = this.getDb();
    if (updates.quality) {
      db.prepare("UPDATE dataset_entries SET quality = ? WHERE id = ?").run(updates.quality, id);
    }
    if (updates.systemPrompt !== undefined) {
      db.prepare("UPDATE dataset_entries SET system_prompt = ? WHERE id = ?").run(updates.systemPrompt, id);
    }
  }

  async deleteDatasetEntry(id: string): Promise<void> {
    const db = this.getDb();
    const entry = db.prepare("SELECT dataset_name FROM dataset_entries WHERE id = ?").get(id) as { dataset_name: string } | undefined;
    db.prepare("DELETE FROM dataset_entries WHERE id = ?").run(id);
    if (entry) {
      db.prepare("UPDATE datasets SET entry_count = entry_count - 1 WHERE name = ?").run(entry.dataset_name);
    }
  }

  async createEdit(sourceId: string, description: string, messages: EditedMessage[]): Promise<ThreadEdit> {
    const db = this.getDb();
    const id = createHash("sha256").update(`${sourceId}:${Date.now()}`).digest("hex").slice(0, 16);
    const createdAt = new Date().toISOString();
    db.prepare(
      "INSERT INTO thread_edits (id, source_id, created_at, description, messages) VALUES (?, ?, ?, ?, ?)",
    ).run(id, sourceId, createdAt, description, JSON.stringify(messages));
    return { id, sourceId, createdAt: new Date(createdAt), description, messages };
  }

  async getEdits(conversationId: string): Promise<ThreadEdit[]> {
    const db = this.getDb();
    const rows = db.prepare(
      "SELECT * FROM thread_edits WHERE source_id = ? ORDER BY created_at DESC",
    ).all(conversationId) as EditRow[];
    return rows.map(rowToEdit);
  }

  async getEdit(editId: string): Promise<ThreadEdit | null> {
    const db = this.getDb();
    const row = db.prepare("SELECT * FROM thread_edits WHERE id = ?").get(editId) as EditRow | undefined;
    return row ? rowToEdit(row) : null;
  }

  close(): void {
    this.db?.close();
    this.db = null;
  }

  static generateId(sourcePath: string, firstTimestamp: string): string {
    return createHash("sha256").update(`${sourcePath}:${firstTimestamp}`).digest("hex").slice(0, 16);
  }
}

interface ConversationRow {
  id: string;
  project_path: string;
  started_at: string;
  updated_at: string;
  message_count: number;
  title: string;
  summary: string | null;
  tags: string;
  status: string;
  source_path: string;
}

function rowToConversation(row: ConversationRow): Conversation {
  return {
    id: row.id,
    projectPath: row.project_path,
    startedAt: new Date(row.started_at),
    updatedAt: new Date(row.updated_at),
    messageCount: row.message_count,
    title: row.title,
    summary: row.summary,
    tags: JSON.parse(row.tags),
    status: row.status as Conversation["status"],
    sourcePath: row.source_path,
  };
}

interface EditRow {
  id: string;
  source_id: string;
  created_at: string;
  description: string;
  messages: string;
}

function rowToEdit(row: EditRow): ThreadEdit {
  return {
    id: row.id,
    sourceId: row.source_id,
    createdAt: new Date(row.created_at),
    description: row.description,
    messages: JSON.parse(row.messages),
  };
}

interface DatasetRow {
  name: string;
  description: string;
  version: number;
  created_at: string;
  updated_at: string;
  entry_count: number;
}

function rowToDataset(row: DatasetRow): Dataset {
  return {
    name: row.name,
    description: row.description,
    version: row.version,
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
    entryCount: row.entry_count,
  };
}

interface DatasetEntryRow {
  id: string;
  dataset_name: string;
  conversation_id: string;
  edit_id: string | null;
  start_index: number;
  end_index: number;
  quality: string;
  system_prompt: string | null;
  messages: string;
  created_at: string;
}

function rowToDatasetEntry(row: DatasetEntryRow): DatasetEntry {
  return {
    id: row.id,
    datasetName: row.dataset_name,
    conversationId: row.conversation_id,
    editId: row.edit_id ?? undefined,
    startIndex: row.start_index,
    endIndex: row.end_index,
    quality: row.quality as QualityLabel,
    systemPrompt: row.system_prompt ?? undefined,
    messages: JSON.parse(row.messages),
    createdAt: new Date(row.created_at),
  };
}
