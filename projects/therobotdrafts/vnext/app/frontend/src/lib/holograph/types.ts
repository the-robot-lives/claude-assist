export type NodeKind =
  | "system"
  | "package"
  | "service"
  | "class"
  | "interface"
  | "function"
  | "database"
  | "agent";

export type EdgeKind =
  | "contains"
  | "calls"
  | "depends_on"
  | "publishes"
  | "stores"
  | "patches";

export interface GraphNode {
  id: string;
  label: string;
  kind: NodeKind;
  parentId?: string;
  packageName?: string;
  description: string;
  metrics: {
    complexity: number;
    churn: number;
    risk: number;
  };
  members?: string[];
  status?: "stable" | "draft" | "review" | "hot";
}

export interface GraphEdge {
  id: string;
  sourceId: string;
  targetId: string;
  kind: EdgeKind;
  label: string;
}

export interface GraphDocument {
  id: string;
  slug: string;
  title: string;
  version: number;
  updatedAt: string;
  summary: string;
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface SceneNode extends GraphNode {
  x: number;
  y: number;
  radius: number;
  depth: number;
  childCount: number;
}

export interface SceneEdge extends GraphEdge {
  source: SceneNode;
  target: SceneNode;
}

export interface ScenePayload {
  nodes: SceneNode[];
  edges: SceneEdge[];
}

export interface PatchOperation {
  id: string;
  type: "add_node" | "connect" | "rename" | "reparent" | "delete";
  targetId: string;
  label: string;
  status: "queued" | "applied" | "review";
}
