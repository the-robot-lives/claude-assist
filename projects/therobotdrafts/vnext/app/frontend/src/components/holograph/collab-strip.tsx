"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { demoDocument } from "@/lib/holograph/fixture";
import {
  createMockHolographChannel,
  createPresenceCursor,
  type HolographRealtimeSnapshot,
  type MockHolographChannel,
  type PresenceUser,
} from "@/lib/holograph/realtime";
import type { GraphDocument } from "@/lib/holograph/types";
import type { CSSProperties } from "react";

export interface CollabStripProps {
  document?: GraphDocument;
  channel?: MockHolographChannel;
  currentUserId?: string;
  focusNodeId?: string | null;
  selectedNodeId?: string | null;
  className?: string;
}

const emptySnapshot: HolographRealtimeSnapshot = {
  topic: "graph:doc:pending",
  documentId: "pending",
  version: 0,
  status: "idle",
  currentUserId: "u-local",
  users: [],
  lastEvent: null,
  lastEventAt: null,
};

export function CollabStrip({
  document = demoDocument,
  channel,
  currentUserId,
  focusNodeId,
  selectedNodeId,
  className,
}: CollabStripProps) {
  const ownedChannelRef = useRef<MockHolographChannel | null>(null);
  const activeChannel = useMemo(() => {
    if (channel) return channel;
    ownedChannelRef.current ??= createMockHolographChannel({
      documentId: document.id,
      lastSeenVersion: document.version,
      currentUserId,
      document,
    });
    return ownedChannelRef.current;
  }, [channel, currentUserId, document]);

  const [snapshot, setSnapshot] = useState<HolographRealtimeSnapshot>(() =>
    activeChannel?.getSnapshot() ?? emptySnapshot,
  );

  useEffect(() => {
    activeChannel.setDocument(document);
    setSnapshot(activeChannel.getSnapshot());
  }, [activeChannel, document]);

  useEffect(() => {
    const unsubscribe = activeChannel.subscribe(() => {
      setSnapshot(activeChannel.getSnapshot());
    });

    activeChannel.connect(document.version);

    return () => {
      unsubscribe();
      activeChannel.disconnect();
    };
  }, [activeChannel, document.version]);

  useEffect(() => {
    const nextFocus = focusNodeId ?? selectedNodeId ?? null;
    if (nextFocus) activeChannel.setFocusNode(snapshot.currentUserId, nextFocus);
  }, [activeChannel, focusNodeId, selectedNodeId, snapshot.currentUserId]);

  useEffect(() => {
    let index = 0;
    const timer = window.setInterval(() => {
      const users = activeChannel.getSnapshot().users;
      const remoteUsers = users.filter((user) => user.userId !== snapshot.currentUserId && user.cursor);
      const user = remoteUsers[index % Math.max(remoteUsers.length, 1)];
      if (!user?.cursor) return;

      index += 1;
      activeChannel.moveCursor(
        user.userId,
        createPresenceCursor(
          user.cursor.nodeId,
          user.cursor.x + (index % 2 === 0 ? 3 : -2),
          user.cursor.y + (index % 3 === 0 ? -2 : 2),
          user.cursor.camera,
        ),
      );
    }, 2400);

    return () => window.clearInterval(timer);
  }, [activeChannel, snapshot.currentUserId]);

  const nodeLabelById = useMemo(
    () => new Map(document.nodes.map((node) => [node.id, node.label])),
    [document.nodes],
  );
  const currentUser = snapshot.users.find((user) => user.userId === snapshot.currentUserId);
  const activeFocusNodeId = focusNodeId ?? currentUser?.focusNodeId ?? selectedNodeId ?? null;
  const focusLabel = activeFocusNodeId
    ? nodeLabelById.get(activeFocusNodeId) ?? activeFocusNodeId
    : "Whole graph";
  const activeUsers = snapshot.users.filter((user) => user.status === "active").length;
  const channelLabel = statusLabel(snapshot.status);

  return (
    <section
      className={className}
      style={styles.shell}
      aria-label="Realtime collaboration preview"
      data-channel-status={snapshot.status}
    >
      <div style={styles.header}>
        <div style={styles.headerCopy}>
          <p style={styles.kicker}>Collaboration</p>
          <h2 style={styles.title}>Mock channel preview</h2>
        </div>
        <div style={styles.status} title={snapshot.topic}>
          <span style={{ ...styles.statusDot, background: statusColor(snapshot.status) }} aria-hidden="true" />
          <span>{channelLabel}</span>
        </div>
      </div>

      <div style={styles.metaGrid}>
        <Metric label="Topic" value={snapshot.topic} />
        <Metric label="Version" value={`v${snapshot.version}`} />
        <Metric label="Active" value={`${activeUsers}/${snapshot.users.length}`} />
      </div>

      <div style={styles.focusRow}>
        <span style={styles.focusLabel}>Focus node</span>
        <strong style={styles.focusValue}>{focusLabel}</strong>
      </div>

      <div style={styles.radar} aria-label="Mock user cursors">
        {snapshot.users.map((user) => (
          <CursorPin key={user.userId} user={user} nodeLabelById={nodeLabelById} />
        ))}
      </div>

      <ul style={styles.userList} aria-label="Mock presence users">
        {snapshot.users.map((user) => (
          <PresenceRow key={user.userId} user={user} nodeLabelById={nodeLabelById} />
        ))}
      </ul>

      <div style={styles.eventLine} aria-live="polite">
        <span style={styles.eventLabel}>Last event</span>
        <span>{snapshot.lastEvent ?? "none"}</span>
      </div>
    </section>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div style={styles.metric}>
      <span style={styles.metricLabel}>{label}</span>
      <strong style={styles.metricValue}>{value}</strong>
    </div>
  );
}

function PresenceRow({
  user,
  nodeLabelById,
}: {
  user: PresenceUser;
  nodeLabelById: Map<string, string>;
}) {
  const focusLabel = user.focusNodeId ? nodeLabelById.get(user.focusNodeId) ?? user.focusNodeId : "Whole graph";

  return (
    <li style={styles.userRow}>
      <span style={{ ...styles.avatar, background: user.color }} aria-hidden="true">
        {user.initials}
      </span>
      <span style={styles.userCopy}>
        <strong style={styles.userName}>{user.name}</strong>
        <span style={styles.userMeta}>
          {user.role} / {focusLabel}
        </span>
      </span>
      <span style={styles.userState}>{user.status}</span>
    </li>
  );
}

function CursorPin({
  user,
  nodeLabelById,
}: {
  user: PresenceUser;
  nodeLabelById: Map<string, string>;
}) {
  if (!user.cursor) return null;

  const nodeLabel = nodeLabelById.get(user.cursor.nodeId) ?? user.cursor.nodeId;

  return (
    <span
      style={{
        ...styles.cursorPin,
        left: `${user.cursor.x}%`,
        top: `${user.cursor.y}%`,
        borderColor: user.color,
        color: user.color,
      }}
      title={`${user.name}: ${nodeLabel}`}
      aria-label={`${user.name} cursor at ${nodeLabel}`}
    >
      <span style={{ ...styles.cursorPoint, background: user.color }} aria-hidden="true" />
      <span style={styles.cursorLabel}>{user.initials}</span>
    </span>
  );
}

function statusLabel(status: HolographRealtimeSnapshot["status"]) {
  if (status === "joining") return "joining";
  if (status === "joined") return "mock live";
  if (status === "leaving") return "leaving";
  if (status === "closed") return "closed";
  return "idle";
}

function statusColor(status: HolographRealtimeSnapshot["status"]) {
  if (status === "joined") return "#45b8ad";
  if (status === "joining") return "#d99b45";
  if (status === "leaving") return "#d99b45";
  if (status === "closed") return "#cf6f66";
  return "#9aa5b2";
}

const mono = "var(--font-mono, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace)";
const sans = "var(--font-sans, Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif)";

const styles = {
  shell: {
    display: "grid",
    gap: 12,
    minWidth: 0,
    color: "var(--hg-text, #e9eef4)",
    background: "#151a21",
    border: "1px solid var(--hg-line, #343c48)",
    borderRadius: 4,
    padding: 12,
    fontFamily: sans,
  },
  header: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12,
  },
  headerCopy: {
    minWidth: 0,
  },
  kicker: {
    margin: 0,
    color: "var(--hg-muted, #9aa5b2)",
    fontFamily: mono,
    fontSize: 11,
    fontWeight: 800,
    letterSpacing: 0,
    textTransform: "uppercase",
  },
  title: {
    margin: 0,
    fontSize: 16,
    lineHeight: 1.1,
    letterSpacing: 0,
  },
  status: {
    minHeight: 28,
    display: "inline-flex",
    alignItems: "center",
    gap: 7,
    padding: "0 9px",
    border: "1px solid var(--hg-line, #343c48)",
    borderRadius: 4,
    background: "#202734",
    color: "var(--hg-muted, #9aa5b2)",
    fontFamily: mono,
    fontSize: 11,
    fontWeight: 800,
    whiteSpace: "nowrap",
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 999,
  },
  metaGrid: {
    display: "grid",
    gridTemplateColumns: "minmax(0, 1.4fr) minmax(64px, 0.6fr) minmax(72px, 0.6fr)",
    gap: 8,
  },
  metric: {
    minWidth: 0,
    display: "grid",
    gap: 2,
    padding: 9,
    border: "1px solid color-mix(in srgb, var(--hg-line, #343c48) 86%, transparent)",
    borderRadius: 4,
    background: "#1d242e",
  },
  metricLabel: {
    color: "var(--hg-muted, #9aa5b2)",
    fontFamily: mono,
    fontSize: 10,
    fontWeight: 800,
    textTransform: "uppercase",
  },
  metricValue: {
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap",
    fontSize: 12,
  },
  focusRow: {
    display: "grid",
    gap: 4,
    padding: 10,
    border: "1px solid #2f3844",
    borderRadius: 4,
    background: "#10151a",
    color: "#e9eef4",
  },
  focusLabel: {
    color: "#aeb8b4",
    fontFamily: mono,
    fontSize: 10,
    fontWeight: 800,
    textTransform: "uppercase",
  },
  focusValue: {
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap",
    fontSize: 13,
  },
  radar: {
    position: "relative",
    height: 116,
    overflow: "hidden",
    border: "1px solid rgba(237, 241, 237, 0.12)",
    borderRadius: 4,
    background:
      "linear-gradient(90deg, rgba(255,255,255,0.08) 1px, transparent 1px), linear-gradient(180deg, rgba(255,255,255,0.08) 1px, transparent 1px), #151a1a",
    backgroundSize: "24px 24px, 24px 24px, auto",
  },
  cursorPin: {
    position: "absolute",
    display: "inline-flex",
    alignItems: "center",
    gap: 4,
    maxWidth: 72,
    transform: "translate(-5px, -5px)",
    fontFamily: mono,
    fontSize: 10,
    fontWeight: 900,
    textShadow: "0 1px 2px rgba(0, 0, 0, 0.45)",
  },
  cursorPoint: {
    width: 10,
    height: 10,
    borderRadius: 999,
    boxShadow: "0 0 0 2px rgba(255, 255, 255, 0.82)",
  },
  cursorLabel: {
    overflow: "hidden",
    color: "#fffdfa",
  },
  userList: {
    display: "grid",
    gap: 8,
    listStyle: "none",
    margin: 0,
    padding: 0,
  },
  userRow: {
    minWidth: 0,
    display: "grid",
    gridTemplateColumns: "32px minmax(0, 1fr) auto",
    alignItems: "center",
    gap: 9,
    padding: 8,
    border: "1px solid color-mix(in srgb, var(--hg-line, #343c48) 86%, transparent)",
    borderRadius: 4,
    background: "#1d242e",
  },
  avatar: {
    width: 32,
    height: 32,
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 999,
    color: "#fffdfa",
    fontFamily: mono,
    fontSize: 11,
    fontWeight: 900,
  },
  userCopy: {
    minWidth: 0,
    display: "grid",
    gap: 2,
  },
  userName: {
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap",
    fontSize: 13,
  },
  userMeta: {
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap",
    color: "var(--hg-muted, #9aa5b2)",
    fontSize: 11,
  },
  userState: {
    color: "var(--hg-muted, #9aa5b2)",
    fontFamily: mono,
    fontSize: 10,
    fontWeight: 800,
    textTransform: "uppercase",
  },
  eventLine: {
    minHeight: 30,
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 8,
    color: "var(--hg-muted, #9aa5b2)",
    fontFamily: mono,
    fontSize: 11,
  },
  eventLabel: {
    fontWeight: 800,
    textTransform: "uppercase",
  },
} satisfies Record<string, CSSProperties>;
