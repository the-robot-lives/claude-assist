import type { GraphDocument, PatchOperation } from "./types";

/**
 * The workspace's persistence seam.
 *
 * One interface, several backings: `CloudDocStore` talks to the Phoenix document API,
 * `LocalDraftStore` keeps browser-local drafts for logged-out and offline use, and the
 * Electron desktop shell will add a filesystem-backed store without the workspace
 * learning about it (see vnext/web-usability-plan.md, phases 1 and 6).
 */

export type DocStoreKind = "cloud" | "local";

/** List-row shape; matches both the Phoenix summary rows and the browser dock's
 * `DocumentSummary`. */
export interface DocSummary {
  id: string;
  slug: string;
  title: string;
  version: number;
  nodeCount: number;
  edgeCount: number;
  updatedAt?: string;
  summary?: string;
}

/** The semantic editor ops are the wire protocol — they match the undo history 1:1 and
 * the backend rejects any other `type`. */
export type DocPatchOperationType = PatchOperation["type"];

export interface DocPatchOperation {
  type: DocPatchOperationType;
  targetId?: string;
  label?: string;
}

export interface DocPatchBatch {
  /** Idempotency key; the server dedups replays of a batch it has already applied. */
  clientEventId: string;
  /** Optimistic lock — the server's `current_version` the batch was composed against. */
  baseVersion?: number;
  operations: DocPatchOperation[];
  /** Post-batch document. Sending it makes the batch authoritative for document state;
   * omitting it advances the event log and version counter only. */
  document?: GraphDocument;
  metadata?: Record<string, unknown>;
}

export interface DocPatchResult {
  documentId: string;
  version: number;
  status: "applied" | "deduplicated";
  snapshot: boolean;
}

export interface DocVersionEntry {
  version: number;
  patch?: Record<string, unknown> | null;
  metadata?: Record<string, unknown> | null;
  actorUserId?: string | null;
  insertedAt?: string;
  nodeCount: number;
  edgeCount: number;
}

export interface DocSaveOptions {
  /** Omit to save unconditionally; supply the loaded version for last-write-wins detection. */
  expectedVersion?: number;
}

export interface DocStore {
  readonly kind: DocStoreKind;
  list(): Promise<DocSummary[]>;
  load(id: string): Promise<GraphDocument>;
  /** Persists a brand-new document; the returned document carries the store's own id. */
  create(document: GraphDocument): Promise<GraphDocument>;
  /** Full-document save. Throws `DocVersionConflictError` when `expectedVersion` is stale. */
  save(document: GraphDocument, options?: DocSaveOptions): Promise<GraphDocument>;
  applyPatchBatch(id: string, batch: DocPatchBatch): Promise<DocPatchResult>;
  listVersions(id: string): Promise<DocVersionEntry[]>;
  restore(id: string, version: number): Promise<GraphDocument>;
}

/** Raised when a save or patch batch was composed against a version the store has since
 * moved past. Callers reload and retry — there is no merge UI. */
export class DocVersionConflictError extends Error {
  readonly expectedVersion?: number;
  readonly currentVersion?: number;

  constructor(message: string, expectedVersion?: number, currentVersion?: number) {
    super(message);
    this.name = "DocVersionConflictError";
    this.expectedVersion = expectedVersion;
    this.currentVersion = currentVersion;
  }
}

/** Raised by a store asked for something its backing cannot do (browser-local drafts have
 * no version history to restore from). */
export class DocStoreUnsupportedError extends Error {
  constructor(operation: string, kind: DocStoreKind) {
    super(`${operation} is not available for ${kind} documents`);
    this.name = "DocStoreUnsupportedError";
  }
}

export function summarizeDocument(document: GraphDocument): DocSummary {
  return {
    id: document.id,
    slug: document.slug,
    title: document.title,
    version: document.version,
    updatedAt: document.updatedAt,
    summary: document.summary,
    nodeCount: document.nodes.length,
    edgeCount: document.edges.length,
  };
}

/** Idempotency key for a patch batch. `randomUUID` is absent on insecure origins and in
 * the plain-node test runner, so fall back to a time-plus-entropy id. */
export function newClientEventId(): string {
  const uuid = globalThis.crypto?.randomUUID;
  if (typeof uuid === "function") return globalThis.crypto.randomUUID();
  return `evt-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}
