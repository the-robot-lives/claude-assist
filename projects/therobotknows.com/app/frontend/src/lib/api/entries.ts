import type {
  CreateEntryInput,
  EntryListResponse,
  EntryResponse,
  ListEntriesParams,
  UpdateEntryInput,
} from "@/types/api";
import { isMockMode } from "./config";
import { request } from "./client";
import { mockEntriesApi } from "./adapters/mock-entries";

export const entriesApi = {
  list(
    universeId: string,
    params: ListEntriesParams = {},
  ): Promise<EntryListResponse> {
    if (isMockMode()) return mockEntriesApi.list(universeId, params);
    const q = new URLSearchParams();
    if (params.page) q.set("page", String(params.page));
    if (params.per_page) q.set("per_page", String(params.per_page));
    if (params.type) q.set("type", params.type);
    if (params.status) q.set("status", params.status);
    if (params.tag) q.set("tag", params.tag);
    if (params.era) q.set("era", params.era);
    if (params.region) q.set("region", params.region);
    if (params.q) q.set("q", params.q);
    const qs = q.toString();
    return request<EntryListResponse>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries${qs ? `?${qs}` : ""}`,
    );
  },

  get(universeId: string, id: string): Promise<EntryResponse> {
    if (isMockMode()) return mockEntriesApi.get(universeId, id);
    return request<EntryResponse>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(id)}`,
    );
  },

  create(universeId: string, input: CreateEntryInput): Promise<EntryResponse> {
    if (isMockMode()) return mockEntriesApi.create(universeId, input);
    return request<EntryResponse>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries`,
      {
        method: "POST",
        body: JSON.stringify({ entry: input }),
      },
    );
  },

  update(
    universeId: string,
    id: string,
    input: UpdateEntryInput,
  ): Promise<EntryResponse> {
    if (isMockMode()) return mockEntriesApi.update(universeId, id, input);
    return request<EntryResponse>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(id)}`,
      {
        method: "PATCH",
        body: JSON.stringify({ entry: input }),
      },
    );
  },

  remove(universeId: string, id: string): Promise<{ message: string }> {
    if (isMockMode()) return mockEntriesApi.remove(universeId, id);
    return request<{ message: string }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(id)}`,
      { method: "DELETE" },
    );
  },

  setStatus(
    universeId: string,
    id: string,
    status: string,
  ): Promise<EntryResponse> {
    if (isMockMode()) return mockEntriesApi.setStatus(universeId, id, status);
    return request<EntryResponse>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(id)}/status`,
      {
        method: "POST",
        body: JSON.stringify({ status }),
      },
    );
  },

  templates(): Promise<{
    templates: Array<{
      type: string;
      name: string;
      fields: string[];
      body_skeleton: string;
    }>;
  }> {
    if (isMockMode()) {
      const types = [
        "character",
        "location",
        "event",
        "faction",
        "object",
        "concept",
        "rule",
      ] as const;
      return Promise.resolve({
        templates: types.map((type) => ({
          type,
          name: type.charAt(0).toUpperCase() + type.slice(1),
          fields: [],
          body_skeleton: `## Summary\n\n## Details\n`,
        })),
      });
    }
    return request("/api/v1/entry-templates");
  },
};
