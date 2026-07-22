import type {
  CreateUniverseInput,
  UniverseListResponse,
  UniverseResponse,
  UniverseStats,
  UpdateUniverseInput,
} from "@/types/api";
import { isMockMode } from "./config";
import { request } from "./client";
import { mockUniversesApi } from "./adapters/mock-universes";

export const universesApi = {
  list(page = 1, perPage = 25): Promise<UniverseListResponse> {
    if (isMockMode()) return mockUniversesApi.list();
    return request<UniverseListResponse>(
      `/api/v1/universes?page=${page}&per_page=${perPage}`,
    );
  },

  get(idOrSlug: string): Promise<UniverseResponse> {
    if (isMockMode()) return mockUniversesApi.get(idOrSlug);
    return request<UniverseResponse>(
      `/api/v1/universes/${encodeURIComponent(idOrSlug)}`,
    );
  },

  create(input: CreateUniverseInput): Promise<UniverseResponse> {
    if (isMockMode()) return mockUniversesApi.create(input);
    return request<UniverseResponse>("/api/v1/universes", {
      method: "POST",
      body: JSON.stringify({ universe: input }),
    });
  },

  update(
    idOrSlug: string,
    input: UpdateUniverseInput,
  ): Promise<UniverseResponse> {
    if (isMockMode()) return mockUniversesApi.update(idOrSlug, input);
    return request<UniverseResponse>(
      `/api/v1/universes/${encodeURIComponent(idOrSlug)}`,
      {
        method: "PATCH",
        body: JSON.stringify({ universe: input }),
      },
    );
  },

  remove(idOrSlug: string): Promise<{ message: string }> {
    if (isMockMode()) return mockUniversesApi.remove(idOrSlug);
    return request<{ message: string }>(
      `/api/v1/universes/${encodeURIComponent(idOrSlug)}`,
      { method: "DELETE" },
    );
  },

  stats(idOrSlug: string): Promise<{ stats: UniverseStats }> {
    if (isMockMode()) return mockUniversesApi.stats(idOrSlug);
    return request<{ stats: UniverseStats }>(
      `/api/v1/universes/${encodeURIComponent(idOrSlug)}/stats`,
    );
  },
};
