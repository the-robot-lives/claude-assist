import type { EdgeKind, GraphDocument, GraphEdge, GraphNode, NodeKind } from "./types";

export type NodeStatus = NonNullable<GraphNode["status"]>;
export type UnknownNodeStatus = NodeStatus | "unknown";
export type GraphDirection = "incoming" | "outgoing" | "both";
export type RiskBand = "low" | "medium" | "high";

export type NodeSearchField = "id" | "label" | "kind" | "status" | "packageName" | "description" | "members";

export interface SearchNodesOptions {
  fields?: readonly NodeSearchField[];
  kinds?: NodeKind | readonly NodeKind[];
  statuses?: UnknownNodeStatus | readonly UnknownNodeStatus[];
  minRisk?: number;
  maxRisk?: number;
  limit?: number;
}

export interface TraceNeighborsOptions {
  direction?: GraphDirection;
  depth?: number;
  edgeKinds?: EdgeKind | readonly EdgeKind[];
}

export interface TraceNeighborsResult {
  origin: GraphNode | null;
  nodes: GraphNode[];
  edges: GraphEdge[];
  nodeIds: string[];
  edgeIds: string[];
  depthByNodeId: Record<string, number>;
}

export interface ShortestPathOptions {
  direction?: GraphDirection;
  edgeKinds?: EdgeKind | readonly EdgeKind[];
}

export interface ShortestPathResult {
  nodes: GraphNode[];
  edges: GraphEdge[];
  nodeIds: string[];
  edgeIds: string[];
  distance: number;
}

export interface RiskRange {
  min?: number;
  max?: number;
  band?: RiskBand;
}

export interface LaneMetrics {
  id: string;
  label: string;
  nodeCount: number;
  edgeCount: number;
  averageRisk: number;
  maxRisk: number;
  statusCounts: Record<UnknownNodeStatus, number>;
}

export interface ParallelLaneGroup {
  parentId: string;
  laneIds: string[];
}

export interface GraphMetrics {
  nodeCount: number;
  edgeCount: number;
  kindCounts: Record<NodeKind, number>;
  edgeKindCounts: Record<EdgeKind, number>;
  statusCounts: Record<UnknownNodeStatus, number>;
  averageComplexity: number;
  averageChurn: number;
  averageRisk: number;
  maxRisk: number;
  hotNodeCount: number;
  rootNodeIds: string[];
  orphanNodeIds: string[];
  danglingEdgeIds: string[];
  missingEndpointIds: string[];
  laneCount: number;
  lanes: LaneMetrics[];
  parallelLaneGroups: ParallelLaneGroup[];
  crossLaneEdgeCount: number;
}

const defaultSearchFields: readonly NodeSearchField[] = [
  "id",
  "label",
  "kind",
  "status",
  "packageName",
  "description",
  "members",
];

type NodeInput = GraphDocument | readonly GraphNode[];

function isGraphDocument(input: NodeInput): input is GraphDocument {
  return "nodes" in input && "edges" in input;
}

function nodesFrom(input: NodeInput) {
  return isGraphDocument(input) ? input.nodes : input;
}

function valuesOf<T extends string>(value: T | readonly T[] | undefined) {
  if (!value) return null;
  return new Set(Array.isArray(value) ? value : [value]);
}

function hasStatus(node: GraphNode, statuses: Set<UnknownNodeStatus>) {
  return statuses.has(node.status ?? "unknown");
}

function matchesRisk(node: GraphNode, minRisk?: number, maxRisk?: number) {
  const risk = node.metrics.risk;
  return (minRisk === undefined || risk >= minRisk) && (maxRisk === undefined || risk <= maxRisk);
}

function emptyStatusCounts(): Record<UnknownNodeStatus, number> {
  return { stable: 0, draft: 0, review: 0, hot: 0, unknown: 0 };
}

function emptyKindCounts(): Record<NodeKind, number> {
  return {
    system: 0,
    package: 0,
    service: 0,
    class: 0,
    interface: 0,
    function: 0,
    database: 0,
    agent: 0,
  };
}

function emptyEdgeKindCounts(): Record<EdgeKind, number> {
  return { contains: 0, calls: 0, depends_on: 0, publishes: 0, stores: 0, patches: 0 };
}

function roundMetric(value: number) {
  return Math.round(value * 100) / 100;
}

function riskRangeForBand(band: RiskBand): Required<Pick<RiskRange, "min" | "max">> {
  if (band === "high") return { min: 60, max: Number.POSITIVE_INFINITY };
  if (band === "medium") return { min: 35, max: 59 };
  return { min: Number.NEGATIVE_INFINITY, max: 34 };
}

function riskFilterRange(filter: RiskBand | RiskRange) {
  if (typeof filter === "string") return riskRangeForBand(filter);
  if (filter.band) {
    const bandRange = riskRangeForBand(filter.band);
    return {
      min: filter.min ?? bandRange.min,
      max: filter.max ?? bandRange.max,
    };
  }

  return {
    min: filter.min ?? Number.NEGATIVE_INFINITY,
    max: filter.max ?? Number.POSITIVE_INFINITY,
  };
}

function edgeKindSet(kinds: EdgeKind | readonly EdgeKind[] | undefined) {
  return valuesOf(kinds);
}

function canTraverse(edge: GraphEdge, nodeId: string, direction: GraphDirection) {
  if (direction === "outgoing") return edge.sourceId === nodeId ? edge.targetId : null;
  if (direction === "incoming") return edge.targetId === nodeId ? edge.sourceId : null;
  if (edge.sourceId === nodeId) return edge.targetId;
  if (edge.targetId === nodeId) return edge.sourceId;
  return null;
}

function adjacencyFor(document: GraphDocument, direction: GraphDirection, allowedKinds: Set<EdgeKind> | null) {
  const adjacency = new Map<string, Array<{ edge: GraphEdge; neighborId: string }>>();

  for (const edge of document.edges) {
    if (allowedKinds && !allowedKinds.has(edge.kind)) continue;

    const targets: Array<[string, string]> = [];
    if (direction === "outgoing" || direction === "both") targets.push([edge.sourceId, edge.targetId]);
    if (direction === "incoming" || direction === "both") targets.push([edge.targetId, edge.sourceId]);

    for (const [nodeId, neighborId] of targets) {
      const next = adjacency.get(nodeId) ?? [];
      next.push({ edge, neighborId });
      adjacency.set(nodeId, next);
    }
  }

  return adjacency;
}

function searchableValue(node: GraphNode, field: NodeSearchField) {
  if (field === "members") return (node.members ?? []).join(" ");
  if (field === "packageName") return node.packageName ?? "";
  if (field === "status") return node.status ?? "";
  return String(node[field]);
}

function searchScore(node: GraphNode, query: string) {
  const label = node.label.toLowerCase();
  const id = node.id.toLowerCase();
  const packageName = (node.packageName ?? "").toLowerCase();
  const members = (node.members ?? []).join(" ").toLowerCase();

  if (label === query || id === query) return 100;
  if (label.startsWith(query)) return 75;
  if (label.includes(query)) return 60;
  if (id.includes(query)) return 45;
  if (packageName.includes(query)) return 30;
  if (members.includes(query)) return 20;
  return 10;
}

export function riskBandFor(value: number): RiskBand {
  if (value >= 60) return "high";
  if (value >= 35) return "medium";
  return "low";
}

export function filterByKind(input: NodeInput, kinds: NodeKind | readonly NodeKind[]) {
  const allowedKinds = valuesOf(kinds);
  if (!allowedKinds) return [...nodesFrom(input)];
  return nodesFrom(input).filter((node) => allowedKinds.has(node.kind));
}

export function filterByStatus(input: NodeInput, statuses: UnknownNodeStatus | readonly UnknownNodeStatus[]) {
  const allowedStatuses = valuesOf(statuses);
  if (!allowedStatuses) return [...nodesFrom(input)];
  return nodesFrom(input).filter((node) => hasStatus(node, allowedStatuses));
}

export function filterByRisk(input: NodeInput, filter: RiskBand | RiskRange) {
  const range = riskFilterRange(filter);
  return nodesFrom(input).filter((node) => matchesRisk(node, range.min, range.max));
}

export function searchNodes(document: GraphDocument, query: string, options: SearchNodesOptions = {}) {
  const normalizedQuery = query.trim().toLowerCase();
  if (!normalizedQuery) return [];

  const fields = options.fields ?? defaultSearchFields;
  const terms = normalizedQuery.split(/\s+/).filter(Boolean);
  const allowedKinds = valuesOf(options.kinds);
  const allowedStatuses = valuesOf(options.statuses);
  const limit = options.limit === undefined ? Number.POSITIVE_INFINITY : Math.max(0, Math.floor(options.limit));

  const ranked = document.nodes
    .map((node, index) => ({ node, index }))
    .filter(({ node }) => {
      if (allowedKinds && !allowedKinds.has(node.kind)) return false;
      if (allowedStatuses && !hasStatus(node, allowedStatuses)) return false;
      if (!matchesRisk(node, options.minRisk, options.maxRisk)) return false;

      const haystack = fields.map((field) => searchableValue(node, field)).join(" ").toLowerCase();
      return terms.every((term) => haystack.includes(term));
    })
    .map(({ node, index }) => ({ node, index, score: searchScore(node, normalizedQuery) }))
    .sort((left, right) => right.score - left.score || left.index - right.index);

  return ranked.slice(0, limit).map(({ node }) => node);
}

export function traceNeighbors(
  document: GraphDocument,
  nodeId: string,
  options: TraceNeighborsOptions = {},
): TraceNeighborsResult {
  const nodeById = new Map(document.nodes.map((node) => [node.id, node]));
  const origin = nodeById.get(nodeId) ?? null;
  if (!origin) {
    return { origin: null, nodes: [], edges: [], nodeIds: [], edgeIds: [], depthByNodeId: {} };
  }

  const direction = options.direction ?? "both";
  const maxDepth = Math.max(0, Math.floor(options.depth ?? 1));
  const allowedKinds = edgeKindSet(options.edgeKinds);
  const visitedNodeIds = new Set<string>([nodeId]);
  const visitedEdgeIds = new Set<string>();
  const depthByNodeId: Record<string, number> = { [nodeId]: 0 };
  const queue: Array<{ id: string; depth: number }> = [{ id: nodeId, depth: 0 }];

  while (queue.length > 0) {
    const current = queue.shift();
    if (!current || current.depth >= maxDepth) continue;

    for (const edge of document.edges) {
      if (allowedKinds && !allowedKinds.has(edge.kind)) continue;
      const neighborId = canTraverse(edge, current.id, direction);
      if (!neighborId || !nodeById.has(neighborId)) continue;

      visitedEdgeIds.add(edge.id);
      if (visitedNodeIds.has(neighborId)) continue;

      visitedNodeIds.add(neighborId);
      depthByNodeId[neighborId] = current.depth + 1;
      queue.push({ id: neighborId, depth: current.depth + 1 });
    }
  }

  return {
    origin,
    nodes: document.nodes.filter((node) => visitedNodeIds.has(node.id)),
    edges: document.edges.filter((edge) => visitedEdgeIds.has(edge.id)),
    nodeIds: document.nodes.filter((node) => visitedNodeIds.has(node.id)).map((node) => node.id),
    edgeIds: document.edges.filter((edge) => visitedEdgeIds.has(edge.id)).map((edge) => edge.id),
    depthByNodeId,
  };
}

export function shortestPath(
  document: GraphDocument,
  sourceId: string,
  targetId: string,
  options: ShortestPathOptions = {},
): ShortestPathResult | null {
  const nodeById = new Map(document.nodes.map((node) => [node.id, node]));
  const source = nodeById.get(sourceId);
  const target = nodeById.get(targetId);
  if (!source || !target) return null;
  if (sourceId === targetId) {
    return { nodes: [source], edges: [], nodeIds: [sourceId], edgeIds: [], distance: 0 };
  }

  const adjacency = adjacencyFor(document, options.direction ?? "both", edgeKindSet(options.edgeKinds));
  const queue = [sourceId];
  const visited = new Set<string>([sourceId]);
  const previous = new Map<string, { nodeId: string; edgeId: string }>();
  let found = false;

  while (queue.length > 0 && !found) {
    const currentId = queue.shift();
    if (!currentId) continue;

    for (const { edge, neighborId } of adjacency.get(currentId) ?? []) {
      if (!nodeById.has(neighborId) || visited.has(neighborId)) continue;

      visited.add(neighborId);
      previous.set(neighborId, { nodeId: currentId, edgeId: edge.id });
      if (neighborId === targetId) {
        found = true;
        break;
      }

      queue.push(neighborId);
    }
  }

  if (!previous.has(targetId)) return null;

  const nodeIds = [targetId];
  const edgeIds: string[] = [];
  let cursor = targetId;
  while (cursor !== sourceId) {
    const prior = previous.get(cursor);
    if (!prior) return null;
    nodeIds.push(prior.nodeId);
    edgeIds.push(prior.edgeId);
    cursor = prior.nodeId;
  }

  nodeIds.reverse();
  edgeIds.reverse();

  const edgeById = new Map(document.edges.map((edge) => [edge.id, edge]));

  return {
    nodes: nodeIds.map((id) => nodeById.get(id)).filter((node): node is GraphNode => Boolean(node)),
    edges: edgeIds.map((id) => edgeById.get(id)).filter((edge): edge is GraphEdge => Boolean(edge)),
    nodeIds,
    edgeIds,
    distance: edgeIds.length,
  };
}

export function graphMetrics(document: GraphDocument): GraphMetrics {
  const nodeById = new Map(document.nodes.map((node) => [node.id, node]));
  const childrenByParent = new Map<string, GraphNode[]>();
  const kindCounts = emptyKindCounts();
  const edgeKindCounts = emptyEdgeKindCounts();
  const statusCounts = emptyStatusCounts();
  const rootNodeIds: string[] = [];
  const orphanNodeIds: string[] = [];
  const missingEndpointIds = new Set<string>();
  const danglingEdgeIds: string[] = [];
  let totalComplexity = 0;
  let totalChurn = 0;
  let totalRisk = 0;
  let maxRisk = 0;
  let hotNodeCount = 0;

  for (const node of document.nodes) {
    kindCounts[node.kind] += 1;
    statusCounts[node.status ?? "unknown"] += 1;
    totalComplexity += node.metrics.complexity;
    totalChurn += node.metrics.churn;
    totalRisk += node.metrics.risk;
    maxRisk = Math.max(maxRisk, node.metrics.risk);
    if (node.status === "hot") hotNodeCount += 1;

    if (!node.parentId) {
      rootNodeIds.push(node.id);
      continue;
    }

    if (!nodeById.has(node.parentId)) orphanNodeIds.push(node.id);
    const children = childrenByParent.get(node.parentId) ?? [];
    children.push(node);
    childrenByParent.set(node.parentId, children);
  }

  for (const edge of document.edges) {
    edgeKindCounts[edge.kind] += 1;
    if (!nodeById.has(edge.sourceId) || !nodeById.has(edge.targetId)) {
      danglingEdgeIds.push(edge.id);
      if (!nodeById.has(edge.sourceId)) missingEndpointIds.add(edge.sourceId);
      if (!nodeById.has(edge.targetId)) missingEndpointIds.add(edge.targetId);
    }
  }

  const rootSet = new Set(rootNodeIds);
  const lanes = document.nodes.filter((node) => node.parentId !== undefined && rootSet.has(node.parentId));
  const laneByNodeId = new Map<string, string>();

  for (const lane of lanes) {
    const queue = [lane.id];
    while (queue.length > 0) {
      const currentId = queue.shift();
      if (!currentId) continue;

      laneByNodeId.set(currentId, lane.id);
      for (const child of childrenByParent.get(currentId) ?? []) queue.push(child.id);
    }
  }

  const laneMetrics = lanes.map((lane) => {
    const laneNodeIds = new Set<string>();
    const queue = [lane.id];
    while (queue.length > 0) {
      const currentId = queue.shift();
      if (!currentId) continue;
      laneNodeIds.add(currentId);
      for (const child of childrenByParent.get(currentId) ?? []) queue.push(child.id);
    }

    const laneNodes = document.nodes.filter((node) => laneNodeIds.has(node.id));
    const laneStatusCounts = emptyStatusCounts();
    let laneRisk = 0;
    let laneMaxRisk = 0;

    for (const node of laneNodes) {
      laneStatusCounts[node.status ?? "unknown"] += 1;
      laneRisk += node.metrics.risk;
      laneMaxRisk = Math.max(laneMaxRisk, node.metrics.risk);
    }

    return {
      id: lane.id,
      label: lane.label,
      nodeCount: laneNodes.length,
      edgeCount: document.edges.filter((edge) => laneNodeIds.has(edge.sourceId) && laneNodeIds.has(edge.targetId)).length,
      averageRisk: roundMetric(laneNodes.length ? laneRisk / laneNodes.length : 0),
      maxRisk: laneMaxRisk,
      statusCounts: laneStatusCounts,
    };
  });

  const parallelLaneGroups = Array.from(childrenByParent.entries())
    .filter(([, children]) => children.length > 1)
    .map(([parentId, children]) => ({ parentId, laneIds: children.map((child) => child.id) }));

  const crossLaneEdgeCount = document.edges.filter((edge) => {
    const sourceLane = laneByNodeId.get(edge.sourceId);
    const targetLane = laneByNodeId.get(edge.targetId);
    return Boolean(sourceLane && targetLane && sourceLane !== targetLane);
  }).length;

  const nodeCount = document.nodes.length;

  return {
    nodeCount,
    edgeCount: document.edges.length,
    kindCounts,
    edgeKindCounts,
    statusCounts,
    averageComplexity: roundMetric(nodeCount ? totalComplexity / nodeCount : 0),
    averageChurn: roundMetric(nodeCount ? totalChurn / nodeCount : 0),
    averageRisk: roundMetric(nodeCount ? totalRisk / nodeCount : 0),
    maxRisk,
    hotNodeCount,
    rootNodeIds,
    orphanNodeIds,
    danglingEdgeIds,
    missingEndpointIds: Array.from(missingEndpointIds),
    laneCount: lanes.length,
    lanes: laneMetrics,
    parallelLaneGroups,
    crossLaneEdgeCount,
  };
}

export const graphAnalysis = {
  filterByKind,
  filterByRisk,
  filterByStatus,
  graphMetrics,
  riskBandFor,
  searchNodes,
  shortestPath,
  traceNeighbors,
};
