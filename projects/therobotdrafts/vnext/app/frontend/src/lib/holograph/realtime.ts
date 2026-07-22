import type { GraphDocument } from "./types";

export const HOLOGRAPH_CHANNEL_TOPIC_PREFIX = "graph:doc:" as const;

export type HolographClientEvent =
  | "doc:join"
  | "doc:leave"
  | "patch:apply"
  | "patch:reject"
  | "cursor:move";

export type HolographServerEvent =
  | "presence:state"
  | "patch:applied"
  | "patch:rejected"
  | "cursor:moved"
  | "presence:diff";

export type HolographChannelEvent = HolographClientEvent | HolographServerEvent;

export type HolographPatchOperationType =
  | "add_node"
  | "connect"
  | "rename"
  | "reparent"
  | "delete";

export interface HolographPatchOperation {
  id: string;
  type: HolographPatchOperationType;
  targetId: string;
  label: string;
  payload?: Record<string, unknown>;
}

export interface PatchBatch {
  id: string;
  documentId: string;
  baseVersion: number;
  authorId: string;
  operations: HolographPatchOperation[];
  status: "proposed" | "applied" | "rejected";
}

export interface CameraPayload {
  x: number;
  y: number;
  zoom: number;
}

export interface PresenceCursor {
  nodeId: string;
  x: number;
  y: number;
  camera: CameraPayload;
}

export interface PresenceUser {
  userId: string;
  name: string;
  initials: string;
  color: string;
  role: "architect" | "reviewer" | "agent" | "observer";
  status: "active" | "idle";
  focusNodeId: string | null;
  cursor: PresenceCursor | null;
  lastSeenAt: string;
}

export interface PhoenixPresenceMeta {
  phx_ref: string;
  online_at: string;
  user: PresenceUser;
}

export interface PhoenixPresenceEntry {
  metas: PhoenixPresenceMeta[];
}

export interface PresenceDiffPayload {
  joins: Record<string, PhoenixPresenceEntry>;
  leaves: Record<string, PhoenixPresenceEntry>;
}

export interface HolographClientEventPayloads {
  "doc:join": { documentId: string; lastSeenVersion: number };
  "doc:leave": { documentId: string };
  "patch:apply": PatchBatch;
  "patch:reject": { patchId: string; reason: string };
  "cursor:move": PresenceCursor;
}

export interface HolographServerEventPayloads {
  "presence:state": { users: PresenceUser[] };
  "patch:applied": { patchId: string; version: number; document: GraphDocument };
  "patch:rejected": { patchId: string; reason: string };
  "cursor:moved": PresenceCursor & { userId: string };
  "presence:diff": PresenceDiffPayload;
}

export type HolographEventPayloads = HolographClientEventPayloads & HolographServerEventPayloads;

export type ChannelStatus = "idle" | "joining" | "joined" | "leaving" | "closed";

export interface HolographRealtimeSnapshot {
  topic: `graph:doc:${string}`;
  documentId: string;
  version: number;
  status: ChannelStatus;
  currentUserId: string;
  users: PresenceUser[];
  lastEvent: HolographChannelEvent | null;
  lastEventAt: string | null;
}

type Listener = () => void;
type EventHandler<EventName extends HolographChannelEvent> = (
  payload: HolographEventPayloads[EventName],
) => void;
type UntypedEventHandler = (payload: unknown) => void;

export interface MockHolographChannelOptions {
  documentId: string;
  lastSeenVersion?: number;
  currentUserId?: string;
  users?: PresenceUser[];
  document?: GraphDocument;
  now?: () => Date;
}

const fallbackCamera: CameraPayload = { x: 50, y: 48, zoom: 1 };

export function graphTopic(documentId: string): `graph:doc:${string}` {
  return `${HOLOGRAPH_CHANNEL_TOPIC_PREFIX}${documentId}`;
}

export function createPresenceCursor(
  nodeId: string,
  x: number,
  y: number,
  camera: CameraPayload = fallbackCamera,
): PresenceCursor {
  return {
    nodeId,
    x: clampPercent(x),
    y: clampPercent(y),
    camera,
  };
}

export function createMockPresenceUsers(now: Date = new Date()): PresenceUser[] {
  const timestamp = now.toISOString();

  return [
    {
      userId: "u-keith",
      name: "Keith Brings",
      initials: "KB",
      color: "#2f8f83",
      role: "architect",
      status: "active",
      focusNodeId: "root",
      cursor: createPresenceCursor("root", 62, 39),
      lastSeenAt: timestamp,
    },
    {
      userId: "u-mira",
      name: "Mira Lane",
      initials: "ML",
      color: "#315d8f",
      role: "reviewer",
      status: "active",
      focusNodeId: "patch-review",
      cursor: createPresenceCursor("patch-review", 28, 66, { x: 42, y: 55, zoom: 0.92 }),
      lastSeenAt: timestamp,
    },
    {
      userId: "u-codex",
      name: "Codex Agent",
      initials: "CX",
      color: "#bc7a22",
      role: "agent",
      status: "idle",
      focusNodeId: "camera-rig",
      cursor: createPresenceCursor("camera-rig", 74, 70, { x: 54, y: 52, zoom: 1.08 }),
      lastSeenAt: timestamp,
    },
  ];
}

export class MockHolographChannel {
  private readonly listeners = new Set<Listener>();
  private readonly handlers: Partial<Record<HolographChannelEvent, Set<UntypedEventHandler>>> = {};
  private readonly now: () => Date;
  private document: GraphDocument | null;
  private snapshot: HolographRealtimeSnapshot;

  constructor(options: MockHolographChannelOptions) {
    this.now = options.now ?? (() => new Date());
    this.document = options.document ?? null;

    const users = options.users ?? createMockPresenceUsers(this.now());
    const currentUserId = options.currentUserId ?? users[0]?.userId ?? "u-local";

    this.snapshot = {
      topic: graphTopic(options.documentId),
      documentId: options.documentId,
      version: options.lastSeenVersion ?? options.document?.version ?? 0,
      status: "idle",
      currentUserId,
      users,
      lastEvent: null,
      lastEventAt: null,
    };
  }

  getSnapshot(): HolographRealtimeSnapshot {
    return this.snapshot;
  }

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  on<EventName extends HolographChannelEvent>(
    event: EventName,
    handler: EventHandler<EventName>,
  ): () => void {
    const handlers = (this.handlers[event] ??= new Set<UntypedEventHandler>());
    const wrappedHandler: UntypedEventHandler = (payload) => {
      handler(payload as HolographEventPayloads[EventName]);
    };
    handlers.add(wrappedHandler);
    return () => handlers.delete(wrappedHandler);
  }

  connect(lastSeenVersion = this.snapshot.version): void {
    this.setSnapshot({
      status: "joining",
      version: lastSeenVersion,
      lastEvent: "doc:join",
    });
    this.push("doc:join", {
      documentId: this.snapshot.documentId,
      lastSeenVersion,
    });
  }

  disconnect(): void {
    this.setSnapshot({ status: "leaving", lastEvent: "doc:leave" });
    this.push("doc:leave", { documentId: this.snapshot.documentId });
  }

  setDocument(document: GraphDocument): void {
    this.document = document;
    this.setSnapshot({
      documentId: document.id,
      topic: graphTopic(document.id),
      version: document.version,
    });
  }

  setFocusNode(userId: string, focusNodeId: string | null): void {
    const users = this.snapshot.users.map((user) =>
      user.userId === userId
        ? { ...user, focusNodeId, lastSeenAt: this.now().toISOString() }
        : user,
    );
    this.setSnapshot({ users, lastEvent: "presence:state" });
    this.emit("presence:state", { users });
  }

  push<EventName extends HolographClientEvent>(
    event: EventName,
    payload: HolographClientEventPayloads[EventName],
  ): void {
    if (event === "doc:join") {
      const joinPayload = payload as HolographClientEventPayloads["doc:join"];
      this.setSnapshot({
        documentId: joinPayload.documentId,
        topic: graphTopic(joinPayload.documentId),
        version: Math.max(this.snapshot.version, joinPayload.lastSeenVersion),
        status: "joined",
        lastEvent: "presence:state",
      });
      this.emit("presence:state", { users: this.snapshot.users });
      return;
    }

    if (event === "doc:leave") {
      this.setSnapshot({ status: "closed", lastEvent: "doc:leave" });
      return;
    }

    if (event === "cursor:move") {
      this.moveCursor(this.snapshot.currentUserId, payload as PresenceCursor);
      return;
    }

    if (event === "patch:apply") {
      this.applyPatch(payload as PatchBatch);
      return;
    }

    if (event === "patch:reject") {
      const rejectPayload = payload as HolographClientEventPayloads["patch:reject"];
      this.emit("patch:rejected", rejectPayload);
      this.setSnapshot({ lastEvent: "patch:rejected" });
    }
  }

  moveCursor(userId: string, cursor: PresenceCursor): void {
    const nextCursor = createPresenceCursor(cursor.nodeId, cursor.x, cursor.y, cursor.camera);
    const users = this.snapshot.users.map((user) =>
      user.userId === userId
        ? {
            ...user,
            status: "active" as const,
            focusNodeId: nextCursor.nodeId,
            cursor: nextCursor,
            lastSeenAt: this.now().toISOString(),
          }
        : user,
    );

    this.setSnapshot({ users, lastEvent: "cursor:moved" });
    this.emit("cursor:moved", { userId, ...nextCursor });
    this.emit("presence:state", { users });
  }

  replacePresence(users: PresenceUser[]): void {
    const previous = new Map(this.snapshot.users.map((user) => [user.userId, user]));
    const next = new Map(users.map((user) => [user.userId, user]));
    const joins: Record<string, PhoenixPresenceEntry> = {};
    const leaves: Record<string, PhoenixPresenceEntry> = {};

    for (const [userId, user] of next) {
      if (!previous.has(userId)) joins[userId] = presenceEntry(user);
    }
    for (const [userId, user] of previous) {
      if (!next.has(userId)) leaves[userId] = presenceEntry(user);
    }

    this.setSnapshot({ users, lastEvent: "presence:diff" });
    this.emit("presence:diff", { joins, leaves });
    this.emit("presence:state", { users });
  }

  private applyPatch(batch: PatchBatch): void {
    if (!this.document) {
      this.emit("patch:rejected", {
        patchId: batch.id,
        reason: "Mock channel has no fixture document to broadcast.",
      });
      this.setSnapshot({ lastEvent: "patch:rejected" });
      return;
    }

    const version = this.snapshot.version + 1;
    const document = {
      ...this.document,
      version,
      updatedAt: this.now().toISOString(),
    };

    this.document = document;
    this.setSnapshot({ version, lastEvent: "patch:applied" });
    this.emit("patch:applied", { patchId: batch.id, version, document });
  }

  private emit<EventName extends HolographServerEvent>(
    event: EventName,
    payload: HolographServerEventPayloads[EventName],
  ): void {
    const handlers = this.handlers[event];
    handlers?.forEach((handler) => handler(payload));
  }

  private setSnapshot(next: Partial<HolographRealtimeSnapshot>): void {
    this.snapshot = {
      ...this.snapshot,
      ...next,
      lastEventAt: next.lastEvent ? this.now().toISOString() : this.snapshot.lastEventAt,
    };
    this.listeners.forEach((listener) => listener());
  }
}

export function createMockHolographChannel(options: MockHolographChannelOptions): MockHolographChannel {
  return new MockHolographChannel(options);
}

function presenceEntry(user: PresenceUser): PhoenixPresenceEntry {
  return {
    metas: [
      {
        phx_ref: `mock-${user.userId}`,
        online_at: user.lastSeenAt,
        user,
      },
    ],
  };
}

function clampPercent(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(100, value));
}
