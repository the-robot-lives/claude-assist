import type {
  CreateEntryInput,
  Entry,
  EntryListResponse,
  EntryResponse,
  EntryStatus,
  EntryType,
  ListEntriesParams,
  UpdateEntryInput,
} from "@/types/api";
import { MOCK_ENTRIES } from "@/lib/mock-data";
import { ApiError } from "../errors";

type StoreEntry = Entry & { universe_slug: string };

function fromMock(): StoreEntry[] {
  return MOCK_ENTRIES.map((e) => ({
    id: e.id,
    universe_id: "ashward-chronicles",
    universe_slug: "ashward-chronicles",
    type: e.type as EntryType,
    status: e.status as EntryStatus,
    title: e.title,
    slug: e.id,
    excerpt: e.excerpt,
    body: { type: "text", text: e.body },
    era: e.era ?? null,
    region: e.region ?? null,
    metadata: {},
    tags: e.tags.map((name) => ({
      id: name,
      name,
      slug: name.toLowerCase().replace(/\s+/g, "-"),
    })),
    word_count: e.wordCount,
    version: e.version,
    created_by: null,
    inserted_at: e.createdAt,
    updated_at: e.updatedAt,
    links: e.connectionIds.map((target, i) => ({
      id: `${e.id}-link-${i}`,
      source_entry_id: e.id,
      target_entry_id: target,
      relationship: "related to",
      excerpt: null,
    })),
  }));
}

let store: StoreEntry[] = fromMock();

function delay<T>(value: T, ms = 60): Promise<T> {
  return new Promise((r) => setTimeout(() => r(value), ms));
}

function matchUniverse(e: StoreEntry, universeId: string) {
  return e.universe_id === universeId || e.universe_slug === universeId;
}

function applyFilters(entries: StoreEntry[], params: ListEntriesParams) {
  return entries.filter((e) => {
    if (params.type && e.type !== params.type) return false;
    if (params.status && e.status !== params.status) return false;
    if (params.era && e.era !== params.era) return false;
    if (params.region && e.region !== params.region) return false;
    if (params.tag) {
      const t = params.tag.toLowerCase();
      if (!e.tags?.some((tag) => tag.slug === t || tag.name.toLowerCase() === t))
        return false;
    }
    if (params.q) {
      const q = params.q.toLowerCase();
      const hay = `${e.title} ${e.excerpt ?? ""}`.toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });
}

function toPublic(e: StoreEntry, includeBody: boolean): Entry {
  const { universe_slug: _, ...rest } = e;
  if (!includeBody) {
    const { body: __, ...summary } = rest;
    return summary as Entry;
  }
  return rest;
}

export const mockEntriesApi = {
  async list(
    universeId: string,
    params: ListEntriesParams = {},
  ): Promise<EntryListResponse> {
    const filtered = applyFilters(
      store.filter((e) => matchUniverse(e, universeId)),
      params,
    );
    const page = params.page ?? 1;
    const per = params.per_page ?? 25;
    const start = (page - 1) * per;
    const slice = filtered.slice(start, start + per);
    return delay({
      entries: slice.map((e) => toPublic(e, false)),
      meta: {
        page,
        per_page: per,
        total: filtered.length,
        total_pages: Math.max(1, Math.ceil(filtered.length / per)),
      },
    });
  },

  async get(universeId: string, id: string): Promise<EntryResponse> {
    const entry = store.find(
      (e) => matchUniverse(e, universeId) && (e.id === id || e.slug === id),
    );
    if (!entry) throw new ApiError("Entry not found", 404);
    return delay({ entry: toPublic(entry, true) });
  },

  async create(
    universeId: string,
    input: CreateEntryInput,
  ): Promise<EntryResponse> {
    const now = new Date().toISOString();
    const id = crypto.randomUUID();
    const slug =
      input.slug ||
      input.title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");
    const entry: StoreEntry = {
      id,
      universe_id: universeId,
      universe_slug: universeId,
      type: input.type,
      status: input.status ?? "draft",
      title: input.title,
      slug,
      excerpt: input.excerpt ?? "",
      body:
        typeof input.body === "string"
          ? { type: "text", text: input.body }
          : (input.body as object) ?? { type: "text", text: "" },
      era: input.era ?? null,
      region: input.region ?? null,
      metadata: input.metadata ?? {},
      tags: (input.tag_names ?? []).map((name) => ({
        id: name,
        name,
        slug: name.toLowerCase().replace(/\s+/g, "-"),
      })),
      word_count: 0,
      version: 1,
      created_by: null,
      inserted_at: now,
      updated_at: now,
      links: [],
    };
    store = [entry, ...store];
    return delay({ entry: toPublic(entry, true) });
  },

  async update(
    universeId: string,
    id: string,
    input: UpdateEntryInput,
  ): Promise<EntryResponse> {
    const idx = store.findIndex(
      (e) => matchUniverse(e, universeId) && e.id === id,
    );
    if (idx < 0) throw new ApiError("Entry not found", 404);
    const prev = store[idx];
    const next: StoreEntry = {
      ...prev,
      ...input,
      body:
        input.body === undefined
          ? prev.body
          : typeof input.body === "string"
            ? { type: "text", text: input.body }
            : input.body,
      tags:
        input.tag_names !== undefined
          ? input.tag_names.map((name) => ({
              id: name,
              name,
              slug: name.toLowerCase().replace(/\s+/g, "-"),
            }))
          : prev.tags,
      version: (prev.version ?? 1) + 1,
      updated_at: new Date().toISOString(),
    };
    store[idx] = next;
    return delay({ entry: toPublic(next, true) });
  },

  async remove(universeId: string, id: string) {
    const before = store.length;
    store = store.filter(
      (e) => !(matchUniverse(e, universeId) && e.id === id),
    );
    if (store.length === before) throw new ApiError("Entry not found", 404);
    return delay({ message: "Entry deleted" });
  },

  async setStatus(universeId: string, id: string, status: string) {
    return this.update(universeId, id, { status: status as EntryStatus });
  },
};
