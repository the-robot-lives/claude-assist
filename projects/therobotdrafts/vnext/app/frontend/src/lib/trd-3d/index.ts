import type { EdgeKind, GraphDocument, GraphEdge, GraphNode, NodeKind } from "../holograph/types";

export const TRD_3D_NODE_KINDS = [
  "system",
  "package",
  "service",
  "class",
  "interface",
  "function",
  "database",
  "agent",
] as const satisfies readonly NodeKind[];

export type Trd3dNodeKind = (typeof TRD_3D_NODE_KINDS)[number];

export type Trd3dNodeShapeKind =
  | "compound-slab"
  | "namespace-slab"
  | "component-capsule"
  | "class-box"
  | "interface-card"
  | "method-pill"
  | "database-cylinder"
  | "actor-hex";

export type TrdUnityNodeConcept =
  | "SceneRoot"
  | "AssemblyNamespace"
  | "MonoBehaviourService"
  | "UmlClass"
  | "UmlInterface"
  | "UmlOperation"
  | "DataStore"
  | "AgentActor";

export type Trd3dLabelLodTier = "full" | "compact" | "glyph" | "hidden";
export type Trd3dEdgeRouteKind = "containment-drop" | "raised-polyline" | "data-arc" | "patch-arc" | "self-loop";
export type Trd3dCameraPresetName = "overview" | "isometric" | "top" | "front" | "focus";

export interface Trd3dVector {
  x: number;
  y: number;
  z: number;
}

export interface Trd3dSlabDimensions {
  width: number;
  height: number;
  depth: number;
}

export interface Trd3dNodeConceptDefinition {
  nodeKind: NodeKind;
  unityConcept: TrdUnityNodeConcept;
  umlConcept: string;
  shapeKind: Trd3dNodeShapeKind;
  defaultLabelLodTier: Trd3dLabelLodTier;
}

export interface Trd3dSceneNode {
  id: string;
  label: string;
  kind: NodeKind;
  parentId?: string;
  packageName?: string;
  status?: GraphNode["status"];
  depth: number;
  childCount: number;
  shapeKind: Trd3dNodeShapeKind;
  unityConcept: TrdUnityNodeConcept;
  umlConcept: string;
  labelLodTier: Trd3dLabelLodTier;
  labelShort: string;
  x: number;
  y: number;
  z: number;
  position: Trd3dVector;
  slab: Trd3dSlabDimensions;
  zLayer: number;
  metrics: GraphNode["metrics"];
  memberCount: number;
}

export interface Trd3dSceneEdge {
  id: string;
  sourceId: string;
  targetId: string;
  kind: EdgeKind;
  label: string;
  source: Trd3dSceneNode;
  target: Trd3dSceneNode;
  routeKind: Trd3dEdgeRouteKind;
  waypoints: Trd3dVector[];
  zLayer: number;
}

export interface Trd3dZLayer {
  index: number;
  name: string;
  z: number;
  nodeIds: string[];
  edgeIds: string[];
}

export interface Trd3dBounds {
  min: Trd3dVector;
  max: Trd3dVector;
  center: Trd3dVector;
  span: Trd3dVector;
}

export interface Trd3dCameraPreset {
  name: Trd3dCameraPresetName;
  label: string;
  position: Trd3dVector;
  target: Trd3dVector;
  up: Trd3dVector;
  fov: number;
  near: number;
  far: number;
  orthographicScale: number;
}

export interface BuildTrd3dSceneOptions {
  focusNodeId?: string | null;
  layerSpacing?: number;
  rootSpacing?: number;
  includeDanglingEdges?: false;
}

export interface Trd3dScene {
  documentId: string;
  slug: string;
  title: string;
  version: number;
  nodes: Trd3dSceneNode[];
  edges: Trd3dSceneEdge[];
  zLayers: Trd3dZLayer[];
  bounds: Trd3dBounds;
  cameraPresets: Record<Trd3dCameraPresetName, Trd3dCameraPreset>;
  omittedEdgeIds: string[];
}

const DEFAULT_LAYER_SPACING = 24;
const DEFAULT_ROOT_SPACING = 54;

const NODE_KIND_ORDER: Record<NodeKind, number> = {
  system: 0,
  package: 1,
  service: 2,
  class: 3,
  interface: 4,
  function: 5,
  database: 6,
  agent: 7,
};

export const TRD_3D_NODE_CONCEPTS: Record<NodeKind, Trd3dNodeConceptDefinition> = {
  system: {
    nodeKind: "system",
    unityConcept: "SceneRoot",
    umlConcept: "system boundary",
    shapeKind: "compound-slab",
    defaultLabelLodTier: "full",
  },
  package: {
    nodeKind: "package",
    unityConcept: "AssemblyNamespace",
    umlConcept: "package",
    shapeKind: "namespace-slab",
    defaultLabelLodTier: "full",
  },
  service: {
    nodeKind: "service",
    unityConcept: "MonoBehaviourService",
    umlConcept: "component",
    shapeKind: "component-capsule",
    defaultLabelLodTier: "compact",
  },
  class: {
    nodeKind: "class",
    unityConcept: "UmlClass",
    umlConcept: "class",
    shapeKind: "class-box",
    defaultLabelLodTier: "compact",
  },
  interface: {
    nodeKind: "interface",
    unityConcept: "UmlInterface",
    umlConcept: "interface",
    shapeKind: "interface-card",
    defaultLabelLodTier: "compact",
  },
  function: {
    nodeKind: "function",
    unityConcept: "UmlOperation",
    umlConcept: "operation",
    shapeKind: "method-pill",
    defaultLabelLodTier: "glyph",
  },
  database: {
    nodeKind: "database",
    unityConcept: "DataStore",
    umlConcept: "datastore",
    shapeKind: "database-cylinder",
    defaultLabelLodTier: "compact",
  },
  agent: {
    nodeKind: "agent",
    unityConcept: "AgentActor",
    umlConcept: "actor",
    shapeKind: "actor-hex",
    defaultLabelLodTier: "compact",
  },
};

const EDGE_ROUTE_KIND: Record<EdgeKind, Trd3dEdgeRouteKind> = {
  contains: "containment-drop",
  calls: "raised-polyline",
  depends_on: "raised-polyline",
  publishes: "data-arc",
  stores: "data-arc",
  patches: "patch-arc",
};

function round(value: number) {
  return Math.round(value * 1000) / 1000;
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}

function vector(x: number, y: number, z: number): Trd3dVector {
  return { x: round(x), y: round(y), z: round(z) };
}

function compareStrings(left: string | undefined, right: string | undefined) {
  return (left ?? "").localeCompare(right ?? "");
}

function compareNodes(left: GraphNode, right: GraphNode) {
  return (
    compareStrings(left.parentId, right.parentId) ||
    NODE_KIND_ORDER[left.kind] - NODE_KIND_ORDER[right.kind] ||
    left.label.localeCompare(right.label) ||
    left.id.localeCompare(right.id)
  );
}

function compareEdges(left: GraphEdge, right: GraphEdge) {
  return (
    left.sourceId.localeCompare(right.sourceId) ||
    left.targetId.localeCompare(right.targetId) ||
    left.kind.localeCompare(right.kind) ||
    left.id.localeCompare(right.id)
  );
}

function childrenByParent(nodes: readonly GraphNode[]) {
  const children = new Map<string, GraphNode[]>();

  for (const node of nodes) {
    if (!node.parentId) continue;
    const list = children.get(node.parentId) ?? [];
    list.push(node);
    children.set(node.parentId, list);
  }

  for (const list of children.values()) list.sort(compareNodes);
  return children;
}

function depthByNode(nodes: readonly GraphNode[]) {
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const depths = new Map<string, number>();
  const resolving = new Set<string>();

  const depthOf = (node: GraphNode): number => {
    const known = depths.get(node.id);
    if (known !== undefined) return known;
    if (resolving.has(node.id)) return 0;

    resolving.add(node.id);
    const parent = node.parentId ? byId.get(node.parentId) : undefined;
    const depth = parent ? depthOf(parent) + 1 : 0;
    resolving.delete(node.id);
    depths.set(node.id, depth);
    return depth;
  };

  for (const node of nodes) depthOf(node);
  return depths;
}

function labelShort(label: string) {
  const words = label
    .split(/[^A-Za-z0-9]+/)
    .map((word) => word.trim())
    .filter(Boolean);
  if (words.length === 0) return label.slice(0, 8);
  if (words.length === 1) return words[0].slice(0, 10);
  return words
    .slice(0, 3)
    .map((word) => word[0]?.toUpperCase() ?? "")
    .join("");
}

function labelLodTier(node: GraphNode, depth: number, childCount: number): Trd3dLabelLodTier {
  if (depth === 0 || node.kind === "system" || childCount >= 3) return "full";
  if (node.status === "hot" || node.metrics.risk >= 60) return "full";
  if (depth <= 2 || TRD_3D_NODE_CONCEPTS[node.kind].defaultLabelLodTier === "compact") return "compact";
  if (depth <= 4) return "glyph";
  return "hidden";
}

function slabDimensions(node: GraphNode, childCount: number): Trd3dSlabDimensions {
  const memberCount = node.members?.length ?? 0;
  const labelWidth = clamp(node.label.length * 0.48, 0, 22);
  const descriptionWeight = clamp(node.description.length / 90, 0, 2.4);
  const kindWidth = node.kind === "system" ? 14 : node.kind === "package" ? 8 : node.kind === "function" ? -2 : 0;
  const kindHeight = node.kind === "system" ? 5 : node.kind === "package" ? 3 : node.kind === "function" ? -1.5 : 0;
  const riskDepth = clamp(node.metrics.risk, 0, 100) / 100;
  const complexityDepth = clamp(node.metrics.complexity, 0, 100) / 140;

  return {
    width: round(clamp(14 + labelWidth + childCount * 1.35 + kindWidth, 12, 56)),
    height: round(clamp(7 + memberCount * 1.7 + descriptionWeight + childCount * 0.4 + kindHeight, 5, 34)),
    depth: round(clamp(2.2 + riskDepth * 2.1 + complexityDepth + childCount * 0.12, 1.8, 7.2)),
  };
}

function sceneNodeFrom(
  node: GraphNode,
  position: Trd3dVector,
  depth: number,
  childCount: number,
): Trd3dSceneNode {
  const concept = TRD_3D_NODE_CONCEPTS[node.kind];
  const slab = slabDimensions(node, childCount);

  return {
    id: node.id,
    label: node.label,
    kind: node.kind,
    parentId: node.parentId,
    packageName: node.packageName,
    status: node.status,
    depth,
    childCount,
    shapeKind: concept.shapeKind,
    unityConcept: concept.unityConcept,
    umlConcept: concept.umlConcept,
    labelLodTier: labelLodTier(node, depth, childCount),
    labelShort: labelShort(node.label),
    x: position.x,
    y: position.y,
    z: position.z,
    position,
    slab,
    zLayer: depth,
    metrics: node.metrics,
    memberCount: node.members?.length ?? 0,
  };
}

function rootPosition(index: number, total: number, spacing: number, z: number) {
  return vector((index - (total - 1) / 2) * spacing, 0, z);
}

function childPosition(parent: Trd3dSceneNode, childDepth: number, index: number, total: number, layerSpacing: number) {
  const radius = Math.max(30, parent.slab.width * 0.74 + total * 3.8 + childDepth * 4.5);
  const angle = -Math.PI / 2 + (Math.PI * 2 * index) / Math.max(total, 1);
  return vector(
    parent.x + Math.cos(angle) * radius,
    parent.y + Math.sin(angle) * radius * 0.64,
    childDepth * layerSpacing,
  );
}

function routeEndpoint(from: Trd3dSceneNode, to: Trd3dSceneNode): Trd3dVector {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const absDx = Math.abs(dx);
  const absDy = Math.abs(dy);
  if (absDx < 0.001 && absDy < 0.001) return vector(from.x, from.y, from.z);

  const xScale = absDx > 0.001 ? from.slab.width / 2 / absDx : Number.POSITIVE_INFINITY;
  const yScale = absDy > 0.001 ? from.slab.height / 2 / absDy : Number.POSITIVE_INFINITY;
  const scale = Math.min(xScale, yScale, 1);
  return vector(from.x + dx * scale, from.y + dy * scale, from.z);
}

function selfLoopWaypoints(node: Trd3dSceneNode, edge: GraphEdge): Trd3dVector[] {
  const lift = edge.kind === "patches" ? 8 : 6;
  const width = node.slab.width / 2 + 6;
  const height = node.slab.height / 2 + 5;
  return [
    vector(node.x + node.slab.width / 2, node.y, node.z),
    vector(node.x + width, node.y - height, node.z + lift),
    vector(node.x - width, node.y - height, node.z + lift),
    vector(node.x - node.slab.width / 2, node.y, node.z),
  ];
}

function edgeWaypoints(edge: GraphEdge, source: Trd3dSceneNode, target: Trd3dSceneNode) {
  if (source.id === target.id) return selfLoopWaypoints(source, edge);

  const start = routeEndpoint(source, target);
  const end = routeEndpoint(target, source);
  const routeKind = EDGE_ROUTE_KIND[edge.kind];
  const layerDelta = Math.abs(target.zLayer - source.zLayer);
  const lift = routeKind === "containment-drop" ? 2.8 : routeKind === "patch-arc" ? 8 : routeKind === "data-arc" ? 6 : 5;
  const routeZ = Math.max(source.z, target.z) + lift + layerDelta * 1.5;
  const midX = (start.x + end.x) / 2;
  const midY = (start.y + end.y) / 2;

  return [
    start,
    vector(start.x, start.y, routeZ),
    vector(midX, midY, routeZ),
    vector(end.x, end.y, routeZ),
    end,
  ];
}

function boundsFor(nodes: readonly Trd3dSceneNode[]): Trd3dBounds {
  if (nodes.length === 0) {
    const zero = vector(0, 0, 0);
    return { min: zero, max: zero, center: zero, span: zero };
  }

  let minX = Number.POSITIVE_INFINITY;
  let minY = Number.POSITIVE_INFINITY;
  let minZ = Number.POSITIVE_INFINITY;
  let maxX = Number.NEGATIVE_INFINITY;
  let maxY = Number.NEGATIVE_INFINITY;
  let maxZ = Number.NEGATIVE_INFINITY;

  for (const node of nodes) {
    minX = Math.min(minX, node.x - node.slab.width / 2);
    maxX = Math.max(maxX, node.x + node.slab.width / 2);
    minY = Math.min(minY, node.y - node.slab.height / 2);
    maxY = Math.max(maxY, node.y + node.slab.height / 2);
    minZ = Math.min(minZ, node.z - node.slab.depth / 2);
    maxZ = Math.max(maxZ, node.z + node.slab.depth / 2);
  }

  const min = vector(minX, minY, minZ);
  const max = vector(maxX, maxY, maxZ);
  return {
    min,
    max,
    center: vector((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2),
    span: vector(max.x - min.x, max.y - min.y, max.z - min.z),
  };
}

function cameraPreset(
  name: Trd3dCameraPresetName,
  label: string,
  position: Trd3dVector,
  target: Trd3dVector,
  scale: number,
): Trd3dCameraPreset {
  return {
    name,
    label,
    position,
    target,
    up: vector(0, 1, 0),
    fov: name === "top" ? 32 : 45,
    near: 0.1,
    far: round(scale * 4 + 160),
    orthographicScale: round(scale * 1.18),
  };
}

function cameraPresets(bounds: Trd3dBounds, focus: Trd3dSceneNode | undefined): Record<Trd3dCameraPresetName, Trd3dCameraPreset> {
  const span = Math.max(bounds.span.x, bounds.span.y, bounds.span.z, 1);
  const center = bounds.center;
  const focusTarget = focus?.position ?? center;
  const focusScale = Math.max(focus?.slab.width ?? 18, focus?.slab.height ?? 12, 18);

  return {
    overview: cameraPreset(
      "overview",
      "Overview",
      vector(center.x, center.y - span * 1.05, center.z + span * 0.9),
      center,
      span,
    ),
    isometric: cameraPreset(
      "isometric",
      "Isometric",
      vector(center.x + span * 0.85, center.y - span * 0.7, center.z + span * 0.8),
      center,
      span,
    ),
    top: cameraPreset("top", "Top", vector(center.x, center.y, center.z + span * 1.35), center, span),
    front: cameraPreset("front", "Front", vector(center.x, center.y - span * 1.35, center.z), center, span),
    focus: cameraPreset(
      "focus",
      "Focus",
      vector(focusTarget.x + focusScale * 1.6, focusTarget.y - focusScale * 1.3, focusTarget.z + focusScale * 1.15),
      focusTarget,
      focusScale,
    ),
  };
}

function zLayers(nodes: readonly Trd3dSceneNode[], edges: readonly Trd3dSceneEdge[], layerSpacing: number) {
  const layers = new Map<number, Trd3dZLayer>();

  for (const node of nodes) {
    const layer = layers.get(node.zLayer) ?? {
      index: node.zLayer,
      name: `depth-${node.zLayer}`,
      z: round(node.zLayer * layerSpacing),
      nodeIds: [],
      edgeIds: [],
    };
    layer.nodeIds.push(node.id);
    layers.set(node.zLayer, layer);
  }

  for (const edge of edges) {
    const layerIndex = Math.floor(edge.zLayer);
    const layer = layers.get(layerIndex) ?? {
      index: layerIndex,
      name: `depth-${layerIndex}`,
      z: round(layerIndex * layerSpacing),
      nodeIds: [],
      edgeIds: [],
    };
    layer.edgeIds.push(edge.id);
    layers.set(layerIndex, layer);
  }

  return Array.from(layers.values())
    .map((layer) => ({
      ...layer,
      nodeIds: [...layer.nodeIds].sort(),
      edgeIds: [...layer.edgeIds].sort(),
    }))
    .sort((left, right) => left.index - right.index);
}

export function buildTrd3dScene(document: GraphDocument, options: BuildTrd3dSceneOptions = {}): Trd3dScene {
  const layerSpacing = options.layerSpacing ?? DEFAULT_LAYER_SPACING;
  const rootSpacing = options.rootSpacing ?? DEFAULT_ROOT_SPACING;
  const sortedNodes = [...document.nodes].sort(compareNodes);
  const byId = new Map(sortedNodes.map((node) => [node.id, node]));
  const children = childrenByParent(sortedNodes);
  const depths = depthByNode(sortedNodes);
  const sceneNodes = new Map<string, Trd3dSceneNode>();

  const placeNode = (node: GraphNode, position: Trd3dVector) => {
    const depth = depths.get(node.id) ?? 0;
    const childCount = children.get(node.id)?.length ?? 0;
    const sceneNode = sceneNodeFrom(node, position, depth, childCount);
    sceneNodes.set(node.id, sceneNode);
    return sceneNode;
  };

  const placeChildren = (parent: Trd3dSceneNode) => {
    const childNodes = children.get(parent.id) ?? [];
    childNodes.forEach((child, index) => {
      const childDepth = depths.get(child.id) ?? parent.depth + 1;
      const placed = placeNode(child, childPosition(parent, childDepth, index, childNodes.length, layerSpacing));
      placeChildren(placed);
    });
  };

  const roots = sortedNodes.filter((node) => !node.parentId || !byId.has(node.parentId));
  roots.forEach((root, index) => {
    const depth = depths.get(root.id) ?? 0;
    const placed = placeNode(root, rootPosition(index, roots.length, rootSpacing, depth * layerSpacing));
    placeChildren(placed);
  });

  const unresolved = sortedNodes.filter((node) => !sceneNodes.has(node.id));
  unresolved.forEach((node, index) => {
    const depth = depths.get(node.id) ?? 0;
    placeNode(node, rootPosition(index + roots.length, unresolved.length + roots.length, rootSpacing, depth * layerSpacing));
  });

  const nodes = Array.from(sceneNodes.values()).sort((left, right) => compareStrings(left.id, right.id));
  const sortedEdges = [...document.edges].sort(compareEdges);
  const edges: Trd3dSceneEdge[] = [];
  const omittedEdgeIds: string[] = [];

  for (const edge of sortedEdges) {
    const source = sceneNodes.get(edge.sourceId);
    const target = sceneNodes.get(edge.targetId);
    if (!source || !target) {
      omittedEdgeIds.push(edge.id);
      continue;
    }

    const waypoints = edgeWaypoints(edge, source, target);
    const routeKind = source.id === target.id ? "self-loop" : EDGE_ROUTE_KIND[edge.kind];
    edges.push({
      id: edge.id,
      sourceId: edge.sourceId,
      targetId: edge.targetId,
      kind: edge.kind,
      label: edge.label,
      source,
      target,
      routeKind,
      waypoints,
      zLayer: round(Math.max(source.zLayer, target.zLayer) + (routeKind === "containment-drop" ? 0.25 : 0.5)),
    });
  }

  const bounds = boundsFor(nodes);
  const focus = (options.focusNodeId ? sceneNodes.get(options.focusNodeId) : undefined) ?? nodes[0];

  return {
    documentId: document.id,
    slug: document.slug,
    title: document.title,
    version: document.version,
    nodes,
    edges,
    zLayers: zLayers(nodes, edges, layerSpacing),
    bounds,
    cameraPresets: cameraPresets(bounds, focus),
    omittedEdgeIds,
  };
}
