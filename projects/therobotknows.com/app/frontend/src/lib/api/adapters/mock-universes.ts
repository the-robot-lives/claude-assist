import type {
  CreateUniverseInput,
  Universe,
  UniverseListResponse,
  UniverseResponse,
  UniverseStats,
  UpdateUniverseInput,
} from "@/types/api";
import { universes as seedUniverses } from "@/data/universes";

/** In-memory store so create/update work during mock-mode UI work. */
let store: Universe[] = seedUniverses.map((u) => ({
  id: u.id,
  slug: u.id,
  name: u.name,
  description: u.description,
  genre: u.genre,
  tone: null,
  config: { genre: u.genre },
  status: "active",
  entry_count: u.entryCount,
  flag_count: u.flagCount,
  connection_count: u.connectionCount,
  role: "owner" as const,
  updated_at: u.updatedAt,
  inserted_at: u.updatedAt,
}));

function delay<T>(value: T, ms = 80): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 64);
}

function find(idOrSlug: string): Universe | undefined {
  return store.find((u) => u.id === idOrSlug || u.slug === idOrSlug);
}

export const mockUniversesApi = {
  async list(): Promise<UniverseListResponse> {
    return delay({
      universes: [...store],
      meta: {
        page: 1,
        per_page: 25,
        total: store.length,
        total_pages: 1,
      },
    });
  },

  async get(idOrSlug: string): Promise<UniverseResponse> {
    const universe = find(idOrSlug);
    if (!universe) {
      const { ApiError } = await import("../errors");
      throw new ApiError("Universe not found", 404);
    }
    return delay({ universe });
  },

  async create(input: CreateUniverseInput): Promise<UniverseResponse> {
    const slug = input.slug || slugify(input.name);
    if (store.some((u) => u.slug === slug)) {
      const { ApiError } = await import("../errors");
      throw new ApiError("Slug has already been taken", 422, {
        slug: ["has already been taken"],
      });
    }
    const now = new Date().toISOString();
    const universe: Universe = {
      id: crypto.randomUUID(),
      slug,
      name: input.name,
      description: input.description ?? "",
      genre: input.genre ?? input.config?.genre ?? null,
      tone: input.tone ?? input.config?.tone ?? null,
      config: input.config ?? {
        genre: input.genre,
        tone: input.tone,
      },
      status: "active",
      entry_count: 0,
      flag_count: 0,
      connection_count: 0,
      role: "owner",
      inserted_at: now,
      updated_at: now,
    };
    store = [universe, ...store];
    return delay({ universe });
  },

  async update(
    idOrSlug: string,
    input: UpdateUniverseInput,
  ): Promise<UniverseResponse> {
    const existing = find(idOrSlug);
    if (!existing) {
      const { ApiError } = await import("../errors");
      throw new ApiError("Universe not found", 404);
    }
    const universe: Universe = {
      ...existing,
      ...input,
      config: input.config
        ? { ...existing.config, ...input.config }
        : existing.config,
      updated_at: new Date().toISOString(),
    };
    store = store.map((u) => (u.id === existing.id ? universe : u));
    return delay({ universe });
  },

  async remove(idOrSlug: string): Promise<{ message: string }> {
    const existing = find(idOrSlug);
    if (!existing) {
      const { ApiError } = await import("../errors");
      throw new ApiError("Universe not found", 404);
    }
    store = store.filter((u) => u.id !== existing.id);
    return delay({ message: "Universe deleted" });
  },

  async stats(idOrSlug: string): Promise<{ stats: UniverseStats }> {
    const universe = find(idOrSlug);
    if (!universe) {
      const { ApiError } = await import("../errors");
      throw new ApiError("Universe not found", 404);
    }
    return delay({
      stats: {
        entry_count: universe.entry_count,
        flag_count: universe.flag_count,
        connection_count: universe.connection_count,
        entry_counts_by_status: {
          canon: Math.max(0, universe.entry_count - 3),
          draft: 1,
          generated: 2,
        },
        recent_activity: [],
      },
    });
  },
};
