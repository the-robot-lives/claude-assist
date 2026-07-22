import { isMockMode } from "./config";
import { request } from "./client";
import type { EntryType } from "@/types/api";

export interface Generation {
  id: string;
  prompt: string;
  entry_type: EntryType;
  status: string;
  output_title?: string | null;
  output_body?: { type?: string; text?: string } | null;
  source_entry_ids: string[];
  citations?: Array<{ entry_id: string; title: string; excerpt?: string }>;
  cost_cents?: number | null;
  error_message?: string | null;
  inserted_at?: string;
  updated_at?: string;
}

let mockGens: Generation[] = [];

export const generationsApi = {
  async list(universeId: string) {
    if (isMockMode()) {
      return {
        generations: mockGens.filter((g) => (g as { universeId?: string }).universeId === universeId || true),
        meta: { page: 1, per_page: 25, total: mockGens.length, total_pages: 1 },
      };
    }
    return request<{ generations: Generation[] }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/generations`,
    );
  },

  async create(
    universeId: string,
    input: {
      prompt: string;
      entry_type: EntryType;
      source_entry_ids?: string[];
      params?: Record<string, unknown>;
    },
  ) {
    if (isMockMode()) {
      const gen: Generation = {
        id: crypto.randomUUID(),
        prompt: input.prompt,
        entry_type: input.entry_type,
        status: "running",
        source_entry_ids: input.source_entry_ids || [],
        citations: [],
        inserted_at: new Date().toISOString(),
      };
      mockGens = [gen, ...mockGens];
      setTimeout(() => {
        const i = mockGens.findIndex((g) => g.id === gen.id);
        if (i >= 0) {
          mockGens[i] = {
            ...mockGens[i],
            status: "complete",
            output_title: input.prompt.slice(0, 80) || "Generated",
            output_body: {
              type: "text",
              text: `## Draft\n\nGenerated from: ${input.prompt}\n\n(Mock generation — switch API mode to live for server jobs.)`,
            },
            citations: (input.source_entry_ids || []).map((id) => ({
              entry_id: id,
              title: id,
            })),
            cost_cents: 5,
          };
        }
      }, 800);
      return { generation: gen };
    }
    return request<{ generation: Generation }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/generations`,
      { method: "POST", body: JSON.stringify({ generation: input }) },
    );
  },

  async get(universeId: string, id: string) {
    if (isMockMode()) {
      const g = mockGens.find((x) => x.id === id);
      if (!g) throw new Error("Not found");
      return { generation: g };
    }
    return request<{ generation: Generation }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/generations/${id}`,
    );
  },

  async promote(universeId: string, id: string) {
    if (isMockMode()) {
      const g = mockGens.find((x) => x.id === id);
      if (g) g.status = "promoted";
      return { generation: g! };
    }
    return request<{ generation: Generation }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/generations/${id}/promote`,
      { method: "POST" },
    );
  },

  async discard(universeId: string, id: string) {
    if (isMockMode()) {
      const g = mockGens.find((x) => x.id === id);
      if (g) g.status = "discarded";
      return { generation: g! };
    }
    return request<{ generation: Generation }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/generations/${id}/discard`,
      { method: "POST" },
    );
  },
};
