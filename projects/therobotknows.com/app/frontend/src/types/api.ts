/** Wire-format types matching app/docs/api/* (snake_case). */

export type EntryType =
  | "character"
  | "location"
  | "event"
  | "faction"
  | "object"
  | "concept"
  | "rule";

export type EntryStatus = "canon" | "draft" | "generated";

export type MemberRole = "owner" | "editor" | "viewer";

export interface PaginationMeta {
  page: number;
  per_page: number;
  total: number;
  total_pages: number;
}

export interface UniverseConfig {
  genre?: string;
  tone?: string;
  naming_conventions?: string;
  constraints?: string[];
  [key: string]: unknown;
}

export interface Universe {
  id: string;
  slug: string;
  name: string;
  description?: string | null;
  genre?: string | null;
  tone?: string | null;
  config?: UniverseConfig;
  status?: string;
  entry_count: number;
  flag_count: number;
  connection_count: number;
  role?: MemberRole;
  created_by?: string | null;
  inserted_at?: string;
  updated_at: string;
}

export interface UniverseListResponse {
  universes: Universe[];
  meta?: PaginationMeta;
}

export interface UniverseResponse {
  universe: Universe;
}

export interface UniverseStats {
  entry_count: number;
  entry_counts_by_type?: Record<string, number>;
  entry_counts_by_status?: Record<string, number>;
  flag_count: number;
  flag_counts_by_severity?: Record<string, number>;
  connection_count: number;
  recent_activity: ActivityItem[];
}

export interface ActivityItem {
  id: string;
  type: string;
  label: string;
  at: string;
  entry_id?: string;
}

export interface Tag {
  id: string;
  name: string;
  slug: string;
  entry_count?: number;
}

export interface EntryLink {
  id: string;
  source_entry_id: string;
  target_entry_id: string;
  relationship: string;
  excerpt?: string | null;
}

export interface Entry {
  id: string;
  universe_id: string;
  type: EntryType;
  status: EntryStatus;
  title: string;
  slug?: string | null;
  excerpt?: string | null;
  body?: unknown;
  era?: string | null;
  region?: string | null;
  metadata?: Record<string, unknown>;
  tags?: Tag[];
  word_count?: number;
  version?: number;
  created_by?: string | null;
  inserted_at?: string;
  updated_at: string;
  links?: EntryLink[];
}

export interface EntryListResponse {
  entries: Entry[];
  meta?: PaginationMeta;
}

export interface EntryResponse {
  entry: Entry;
}

export interface CreateUniverseInput {
  name: string;
  slug?: string;
  description?: string;
  genre?: string;
  tone?: string;
  config?: UniverseConfig;
}

export interface UpdateUniverseInput {
  name?: string;
  description?: string;
  genre?: string;
  tone?: string;
  config?: UniverseConfig;
}

export interface CreateEntryInput {
  type: EntryType;
  status?: EntryStatus;
  title: string;
  slug?: string;
  excerpt?: string;
  body?: unknown;
  era?: string;
  region?: string;
  metadata?: Record<string, unknown>;
  tag_names?: string[];
}

export interface UpdateEntryInput {
  type?: EntryType;
  status?: EntryStatus;
  title?: string;
  slug?: string;
  excerpt?: string;
  body?: unknown;
  era?: string;
  region?: string;
  metadata?: Record<string, unknown>;
  tag_names?: string[];
}

export interface ListEntriesParams {
  page?: number;
  per_page?: number;
  type?: EntryType;
  status?: EntryStatus;
  tag?: string;
  era?: string;
  region?: string;
  q?: string;
}
