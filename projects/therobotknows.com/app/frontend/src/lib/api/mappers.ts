import type { Entry as ApiEntry, Universe as ApiUniverse } from "@/types/api";
import type { Entry as UiEntry } from "@/types/entry";
import type { Universe as UiUniverse } from "@/types/universe";

/** Map API universe (snake_case) → existing UI Universe type. */
export function toUiUniverse(u: ApiUniverse): UiUniverse {
  return {
    id: u.slug || u.id,
    name: u.name,
    genre: u.genre ?? "",
    description: u.description ?? "",
    entryCount: u.entry_count ?? 0,
    flagCount: u.flag_count ?? 0,
    connectionCount: u.connection_count ?? 0,
    updatedAt: u.updated_at,
  };
}

function bodyToString(body: unknown): string {
  if (typeof body === "string") return body;
  if (body && typeof body === "object") {
    const b = body as Record<string, unknown>;
    if (typeof b.text === "string") return b.text;
    try {
      return JSON.stringify(body, null, 2);
    } catch {
      return "";
    }
  }
  return "";
}

/** Map API entry → UI Entry type used by existing components. */
export function toUiEntry(e: ApiEntry): UiEntry {
  return {
    id: e.slug || e.id,
    type: e.type,
    status: e.status,
    title: e.title,
    excerpt: e.excerpt ?? "",
    body: bodyToString(e.body),
    tags: (e.tags ?? []).map((t) => t.name),
    era: e.era ?? undefined,
    region: e.region ?? undefined,
    wordCount: e.word_count ?? 0,
    version: e.version ?? 1,
    createdAt: e.inserted_at ?? e.updated_at,
    updatedAt: e.updated_at,
    connectionIds: (e.links ?? []).map(
      (l) =>
        (l.source_entry_id === e.id ? l.target_entry_id : l.source_entry_id) ||
        l.target_entry_id,
    ),
  };
}

/** Preserve draft status for components that understand it. */
export function toUiEntryWithDraft(e: ApiEntry): UiEntry & { apiStatus: string; apiId: string } {
  return {
    ...toUiEntry(e),
    status: e.status === "canon" ? "canon" : e.status === "generated" ? "generated" : "generated",
    apiStatus: e.status,
    apiId: e.id,
  };
}
