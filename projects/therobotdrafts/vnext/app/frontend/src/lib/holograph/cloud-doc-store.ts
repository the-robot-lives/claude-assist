import { ApiError, apiRequest } from "@/lib/api";
import { isGraphDocument, normalizeGraphDocument } from "./document-io";
import {
  DocVersionConflictError,
  type DocPatchBatch,
  type DocPatchResult,
  type DocSaveOptions,
  type DocStore,
  type DocSummary,
  type DocVersionEntry,
} from "./doc-store";
import type { GraphDocument } from "./types";

/** Envelope every document route answers with: the canonical payload plus the row
 * metadata the jsonb envelope cannot carry (project/org ids, DB version, status). */
interface DocEnvelope {
  data?: unknown;
  meta?: {
    documentId?: string;
    projectId?: string | null;
    organizationId?: string | null;
    currentVersion?: number;
    status?: string;
    updatedAt?: string;
  };
}

interface ConflictBody {
  error?: {
    code?: string;
    expected_version?: number;
    current_version?: number;
    message?: string;
  };
}

function asDocument(payload: DocEnvelope, context: string): GraphDocument {
  if (!isGraphDocument(payload.data)) {
    throw new Error(`${context}: response did not contain a graph document`);
  }
  return normalizeGraphDocument(payload.data);
}

/** The Phoenix 409 body carries the versions; anything else keeps its own error. */
function rethrow(error: unknown): never {
  if (error instanceof ApiError && error.status === 409) {
    const { error: detail } = (error.body ?? {}) as ConflictBody;
    throw new DocVersionConflictError(
      detail?.message ?? error.message,
      detail?.expected_version,
      detail?.current_version,
    );
  }
  throw error;
}

/**
 * Phase-1 document store: the Phoenix `HoloGraph.Docs` API, project-scoped and PBAC'd.
 * Every route is `:authenticated`, so this store is only ever handed to a signed-in
 * session with a resolved project (see `useDocStore`).
 */
export class CloudDocStore implements DocStore {
  readonly kind = "cloud" as const;

  constructor(readonly projectId: string) {}

  async list(): Promise<DocSummary[]> {
    const payload = await apiRequest<{ data?: DocSummary[] }>(
      `/api/v1/projects/${this.projectId}/docs`,
    );
    return payload.data ?? [];
  }

  async load(id: string): Promise<GraphDocument> {
    const payload = await apiRequest<DocEnvelope>(`/api/v1/docs/${id}`);
    return asDocument(payload, `load ${id}`);
  }

  async create(document: GraphDocument): Promise<GraphDocument> {
    const payload = await apiRequest<DocEnvelope>(`/api/v1/projects/${this.projectId}/docs`, {
      method: "POST",
      body: JSON.stringify({
        document,
        title: document.title,
        slug: document.slug,
        summary: document.summary,
      }),
    }).catch(rethrow);
    return asDocument(payload, "create document");
  }

  async save(document: GraphDocument, options: DocSaveOptions = {}): Promise<GraphDocument> {
    const payload = await apiRequest<DocEnvelope>(`/api/v1/docs/${document.id}`, {
      method: "PUT",
      body: JSON.stringify({
        document,
        title: document.title,
        summary: document.summary,
        expected_version: options.expectedVersion,
      }),
    }).catch(rethrow);
    return asDocument(payload, `save ${document.id}`);
  }

  async applyPatchBatch(id: string, batch: DocPatchBatch): Promise<DocPatchResult> {
    const payload = await apiRequest<{ data?: DocPatchResult }>(`/api/v1/docs/${id}/patches`, {
      method: "POST",
      body: JSON.stringify({
        client_event_id: batch.clientEventId,
        base_version: batch.baseVersion,
        operations: batch.operations,
        document: batch.document,
        metadata: batch.metadata,
      }),
    }).catch(rethrow);

    if (!payload.data) throw new Error(`patch batch for ${id} returned no result`);
    return payload.data;
  }

  async listVersions(id: string): Promise<DocVersionEntry[]> {
    const payload = await apiRequest<{ data?: DocVersionEntry[] }>(`/api/v1/docs/${id}/versions`);
    return payload.data ?? [];
  }

  async restore(id: string, version: number): Promise<GraphDocument> {
    const payload = await apiRequest<DocEnvelope>(
      `/api/v1/docs/${id}/versions/${version}/restore`,
      { method: "POST" },
    ).catch(rethrow);
    return asDocument(payload, `restore ${id}@${version}`);
  }
}
