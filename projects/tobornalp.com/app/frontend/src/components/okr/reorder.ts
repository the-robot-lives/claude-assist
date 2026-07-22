// Pure drag/drop helpers for the OKR tree (US-069 FR-9). The security-relevant
// piece: `canReparent` client-pre-checks a drop so illegal targets (self, own
// descendant, or a move that would exceed the depth cap) are disabled before the
// request. The server independently re-validates and returns 422 on a raced
// violation; the UI reconciles by reloading the tree — it never assumes success.

import type { ObjectiveTreeNode } from "@/lib/api";

// Mirror of the backend @max_depth (root counted as depth 1).
export const MAX_DEPTH = 6;

// All ids in a subtree, including the root node itself.
export function subtreeIds(node: ObjectiveTreeNode): Set<string> {
  const out = new Set<string>([node.id]);
  for (const child of node.children) {
    for (const id of subtreeIds(child)) out.add(id);
  }
  return out;
}

// Height of a subtree: a lone node = 1, a node with one level of children = 2, …
export function subtreeHeight(node: ObjectiveTreeNode): number {
  if (node.children.length === 0) return 1;
  return 1 + Math.max(...node.children.map(subtreeHeight));
}

// Depth of `id` from its root (root = 1). Returns 0 if not found.
export function nodeDepth(id: string, forest: ObjectiveTreeNode[], depth = 1): number {
  for (const node of forest) {
    if (node.id === id) return depth;
    const found = nodeDepth(id, node.children, depth + 1);
    if (found) return found;
  }
  return 0;
}

export function findNode(id: string, forest: ObjectiveTreeNode[]): ObjectiveTreeNode | null {
  for (const node of forest) {
    if (node.id === id) return node;
    const found = findNode(id, node.children);
    if (found) return found;
  }
  return null;
}

// Can `dragId` be reparented under `targetId`? False when target is the node
// itself, one of its descendants (would-be cycle), or when the move would push the
// dragged subtree's deepest node past MAX_DEPTH.
export function canReparent(dragId: string, targetId: string, forest: ObjectiveTreeNode[]): boolean {
  if (dragId === targetId) return false;

  const drag = findNode(dragId, forest);
  if (!drag) return false;

  // target inside the dragged subtree ⇒ cycle
  if (subtreeIds(drag).has(targetId)) return false;

  // depth: target's depth + dragged subtree height must stay within the cap
  const targetDepth = nodeDepth(targetId, forest);
  if (targetDepth === 0) return false;
  return targetDepth + subtreeHeight(drag) <= MAX_DEPTH;
}
