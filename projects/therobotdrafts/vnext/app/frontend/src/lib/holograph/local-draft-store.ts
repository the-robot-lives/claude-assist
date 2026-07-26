import { demoDocument } from "./fixture";
import { normalizeGraphDocument, readGraphDocumentJson } from "./document-io";
import {
  DocStoreUnsupportedError,
  summarizeDocument,
  type DocPatchBatch,
  type DocPatchResult,
  type DocStore,
  type DocSummary,
  type DocVersionEntry,
} from "./doc-store";
import type { GraphDocument } from "./types";

/** The in-progress document, rewritten on every edit purely for crash recovery. Used by
 * both storage modes — a cloud-backed session still restores from here after a reload
 * that beat the autosave flush. */
const draftKey = "trd:vnext:active-document";
/** Documents the user explicitly saved while logged out, keyed by document id. */
const localDocumentsKey = "trd:vnext:local-documents";

export function hasActiveDraft(): boolean {
  return typeof window !== "undefined" && window.localStorage.getItem(draftKey) !== null;
}

export function readActiveDraft(): GraphDocument | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(draftKey);
  if (!raw) return null;
  try {
    return readGraphDocumentJson(raw);
  } catch {
    return null;
  }
}

export function writeActiveDraft(document: GraphDocument) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(draftKey, JSON.stringify(document));
  } catch {
    /* quota — the draft is crash recovery, never a source of truth */
  }
}

function readLocalDocuments(): Record<string, GraphDocument> {
  if (typeof window === "undefined") return {};
  try {
    const raw = window.localStorage.getItem(localDocumentsKey);
    return raw ? (JSON.parse(raw) as Record<string, GraphDocument>) : {};
  } catch {
    return {};
  }
}

function writeLocalDocuments(documents: Record<string, GraphDocument>) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(localDocumentsKey, JSON.stringify(documents));
  } catch {
    /* quota — a failed local save surfaces to the caller as an unchanged list */
  }
}

/**
 * Browser-local store for logged-out and offline use.
 *
 * This is deliberately not a sync target: it holds the bundled example model plus
 * whatever the user saved without an account, so the workspace stays fully usable
 * (and the demo keeps working) with no backend at all. Cloud documents remain the
 * system of record whenever a session has one.
 */
export class LocalDraftStore implements DocStore {
  readonly kind = "local" as const;

  async list(): Promise<DocSummary[]> {
    const local = Object.values(readLocalDocuments()).map(summarizeDocument);
    const shadowed = local.some((entry) => entry.id === demoDocument.id);
    return shadowed ? local : [...local, summarizeDocument(demoDocument)];
  }

  async load(id: string): Promise<GraphDocument> {
    const stored = readLocalDocuments()[id];
    if (stored) return normalizeGraphDocument(stored);
    if (id === demoDocument.id) return normalizeGraphDocument(demoDocument);
    throw new Error(`Document ${id} is not stored in this browser`);
  }

  async create(document: GraphDocument): Promise<GraphDocument> {
    // The version counter stays client-owned here — unlike the server, this store does
    // not assign one, so a saved draft keeps the version the editor has been showing.
    return this.put({ ...document, id: `local-${Date.now().toString(36)}` });
  }

  async save(document: GraphDocument): Promise<GraphDocument> {
    return this.put(document);
  }

  async applyPatchBatch(id: string, batch: DocPatchBatch): Promise<DocPatchResult> {
    const base = batch.document ?? (await this.load(id));
    const saved = this.put({ ...base, id });
    return { documentId: saved.id, version: saved.version, status: "applied", snapshot: false };
  }

  async listVersions(): Promise<DocVersionEntry[]> {
    return [];
  }

  async restore(): Promise<GraphDocument> {
    throw new DocStoreUnsupportedError("Version history", this.kind);
  }

  private put(document: GraphDocument): GraphDocument {
    const next = { ...document, updatedAt: new Date().toISOString() };
    const documents = readLocalDocuments();
    documents[next.id] = next;
    writeLocalDocuments(documents);
    return next;
  }
}
