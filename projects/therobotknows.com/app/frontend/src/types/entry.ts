import type { EntryType, EntryStatus } from "@/lib/constants";

export interface Entry {
  id: string;
  type: EntryType;
  status: EntryStatus;
  title: string;
  excerpt: string;
  body: string;
  tags: string[];
  era?: string;
  region?: string;
  wordCount: number;
  version: number;
  createdAt: string;
  updatedAt: string;
  connectionIds: string[];
  /** Backend UUID when distinct from slug/id used in routes */
  apiId?: string;
}

export interface Connection {
  id: string;
  sourceId: string;
  targetId: string;
  relationship: string;
}
