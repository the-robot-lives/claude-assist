import { isMockMode } from "./config";
import { request } from "./client";
import { entriesApi } from "./entries";
import type { FlagSeverity } from "@/lib/constants";

export interface ConsistencyIssue {
  id: string;
  severity: FlagSeverity;
  kind: string;
  title: string;
  detail: string;
  entry_ids: string[];
  status: string;
  resolution?: Record<string, unknown> | null;
}

let mockIssues: ConsistencyIssue[] = [];

export const consistencyApi = {
  async list(universeId: string, status = "open") {
    if (isMockMode()) {
      return {
        issues: mockIssues.filter((i) => status === "all" || i.status === status),
      };
    }
    return request<{ issues: ConsistencyIssue[] }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/consistency/issues?status=${status}`,
    );
  },

  async run(universeId: string) {
    if (isMockMode()) {
      const { entries } = await entriesApi.list(universeId, { per_page: 100 });
      const byTitle = new Map<string, typeof entries>();
      for (const e of entries) {
        const k = e.title.toLowerCase();
        byTitle.set(k, [...(byTitle.get(k) || []), e]);
      }
      mockIssues = [];
      for (const [, group] of byTitle) {
        if (group.length > 1) {
          mockIssues.push({
            id: crypto.randomUUID(),
            severity: "error",
            kind: "duplicate_name",
            title: `Duplicate name — '${group[0].title}'`,
            detail: `${group.length} entries share this title.`,
            entry_ids: group.map((e) => e.id),
            status: "open",
          });
        }
      }
      if (mockIssues.length === 0) {
        mockIssues.push({
          id: crypto.randomUUID(),
          severity: "suggestion",
          kind: "timeline_lite",
          title: "No critical issues found",
          detail: "Duplicate-name and orphan checks passed on mock data.",
          entry_ids: [],
          status: "open",
        });
      }
      return { issues_found: mockIssues.length, issues: mockIssues };
    }
    return request(
      `/api/v1/universes/${encodeURIComponent(universeId)}/consistency/run`,
      { method: "POST" },
    );
  },

  async resolve(
    universeId: string,
    id: string,
    resolution: { status?: string; note?: string },
  ) {
    if (isMockMode()) {
      mockIssues = mockIssues.map((i) =>
        i.id === id
          ? { ...i, status: resolution.status || "resolved", resolution }
          : i,
      );
      return { issue: mockIssues.find((i) => i.id === id)! };
    }
    return request(
      `/api/v1/universes/${encodeURIComponent(universeId)}/consistency/issues/${id}/resolve`,
      {
        method: "POST",
        body: JSON.stringify({ resolution }),
      },
    );
  },
};
