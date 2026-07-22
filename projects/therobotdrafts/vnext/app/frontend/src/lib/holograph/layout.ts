import type { GraphDocument, GraphNode, SceneNode, ScenePayload } from "./types";

const center = { x: 50, y: 48 };

const kindWeight: Record<GraphNode["kind"], number> = {
  system: 2.2,
  package: 1.45,
  service: 1.25,
  class: 0.95,
  interface: 0.9,
  function: 0.78,
  database: 1.05,
  agent: 1.12,
};

function metricRadius(node: GraphNode, childCount: number) {
  const risk = node.metrics.risk / 100;
  const complexity = node.metrics.complexity / 100;
  return 4.4 + kindWeight[node.kind] * 2.2 + childCount * 0.45 + risk * 1.4 + complexity * 1.2;
}

export function packDocument(document: GraphDocument, focusId: string | null): ScenePayload {
  const childrenByParent = new Map<string, GraphNode[]>();
  for (const node of document.nodes) {
    if (!node.parentId) continue;
    const children = childrenByParent.get(node.parentId) ?? [];
    children.push(node);
    childrenByParent.set(node.parentId, children);
  }

  const nodeById = new Map(document.nodes.map((node) => [node.id, node]));
  const root = focusId ? nodeById.get(focusId) ?? nodeById.get("root") : nodeById.get("root");
  const rootId = root?.id ?? "root";
  const visibleIds = new Set<string>([rootId]);

  const firstRing = childrenByParent.get(rootId) ?? [];
  for (const child of firstRing) visibleIds.add(child.id);
  for (const child of firstRing) {
    for (const grandChild of childrenByParent.get(child.id) ?? []) visibleIds.add(grandChild.id);
  }

  const visibleNodes = document.nodes.filter((node) => visibleIds.has(node.id));
  const sceneNodes = new Map<string, SceneNode>();

  const placeNode = (
    node: GraphNode,
    index: number,
    total: number,
    parent: SceneNode | null,
    depth: number,
  ) => {
    const childCount = childrenByParent.get(node.id)?.length ?? 0;
    const radius = node.id === rootId ? 11 : metricRadius(node, childCount);
    let x = center.x;
    let y = center.y;

    if (parent) {
      const orbit = depth === 1 ? 29 : Math.max(10, parent.radius + 7.8);
      const angle = -Math.PI / 2 + (Math.PI * 2 * index) / Math.max(total, 1);
      x = parent.x + Math.cos(angle) * orbit;
      y = parent.y + Math.sin(angle) * orbit * 0.64;
    }

    const sceneNode: SceneNode = { ...node, x, y, radius, depth, childCount };
    sceneNodes.set(node.id, sceneNode);
    return sceneNode;
  };

  const rootNode = placeNode(nodeById.get(rootId) ?? visibleNodes[0], 0, 1, null, 0);
  const ring = visibleNodes.filter((node) => node.parentId === rootId);
  ring.forEach((node, index) => {
    const placed = placeNode(node, index, ring.length, rootNode, 1);
    const subRing = visibleNodes.filter((candidate) => candidate.parentId === node.id);
    subRing.forEach((child, childIndex) => placeNode(child, childIndex, subRing.length, placed, 2));
  });

  const nodes = visibleNodes
    .map((node) => sceneNodes.get(node.id))
    .filter((node): node is SceneNode => Boolean(node));

  const edges = document.edges
    .map((edge) => {
      const source = sceneNodes.get(edge.sourceId);
      const target = sceneNodes.get(edge.targetId);
      if (!source || !target) return null;
      return { ...edge, source, target };
    })
    .filter((edge): edge is NonNullable<typeof edge> => Boolean(edge));

  return { nodes, edges };
}
