import { isMockMode } from "./config";
import { request } from "./client";
import { entriesApi } from "./entries";
import type { EntryType, EntryStatus } from "@/types/api";

export interface GraphNode {
  id: string;
  slug?: string | null;
  label: string;
  type: EntryType;
  status: EntryStatus;
  era?: string | null;
  region?: string | null;
}

export interface GraphEdge {
  id?: string;
  source: string;
  target: string;
  relationship: string;
  excerpt?: string | null;
}

export interface GraphParams {
  type?: string;
  status?: string;
  tag?: string;
  era?: string;
  region?: string;
}

export const graphApi = {
  async get(
    universeId: string,
    params: GraphParams = {},
  ): Promise<{ nodes: GraphNode[]; edges: GraphEdge[] }> {
    if (isMockMode()) {
      const { entries } = await entriesApi.list(universeId, { per_page: 100 });
      const filtered = entries.filter((e) => {
        if (params.type && e.type !== params.type) return false;
        if (params.status && e.status !== params.status) return false;
        return true;
      });
      const nodes: GraphNode[] = filtered.map((e) => ({
        id: e.id,
        slug: e.slug,
        label: e.title,
        type: e.type,
        status: e.status,
        era: e.era,
        region: e.region,
      }));
      const edges: GraphEdge[] = [];
      for (const e of filtered) {
        for (const l of e.links || []) {
          edges.push({
            id: l.id,
            source: l.source_entry_id,
            target: l.target_entry_id,
            relationship: l.relationship,
            excerpt: l.excerpt,
          });
        }
      }
      return { nodes, edges };
    }
    const q = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v) q.set(k, v);
    });
    const qs = q.toString();
    return request(
      `/api/v1/universes/${encodeURIComponent(universeId)}/graph${qs ? `?${qs}` : ""}`,
    );
  },
};
