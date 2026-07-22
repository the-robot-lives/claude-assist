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
  stereotype?: string;
  uml?: {
    elementType?: string;
    visibility?: "public" | "private" | "protected" | "package";
    abstract?: boolean;
    attributes?: string[];
    operations?: string[];
  };
  trd3d?: {
    position: { x: number; y: number; z: number };
    rotation?: { x: number; y: number; z: number };
    dimensions?: { width: number; height: number; depth: number };
    layer?: number;
    shape?: "slab" | "package" | "component" | "cylinder" | "sphere" | "actor" | "interface";
    color?: string;
    /** True when the position was placed by hand (drag-drop); the renderer then keeps it
     * instead of the synthesized layout position (mirrors Unity's layoutProvenance). */
    authored?: boolean;
  };
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
  uml?: {
    relationship:
      | "association"
      | "dependency"
      | "generalization"
      | "realization"
      | "composition"
      | "aggregation"
      | "deployment"
      | "trace";
    sourceMultiplicity?: string;
    targetMultiplicity?: string;
    dashed?: boolean;
    arrow?: "open" | "closed" | "triangle" | "diamond" | "none";
  };
  trd3d?: {
    waypoints?: Array<{ x: number; y: number; z: number }>;
    layer?: number;
  };
}

export interface GraphDocument {
  id: string;
  slug: string;
  title: string;
  version: number;
  updatedAt: string;
  summary: string;
  modelKind?: "uml" | "sysml" | "bpmn" | "archimate" | "code";
  view?: {
    projection: "trd-3d-uml" | "bubble-pack" | "class-diagram" | "component-diagram";
    activeLayer?: number;
    camera?: {
      target: { x: number; y: number; z: number };
      yaw: number;
      pitch: number;
      distance: number;
    };
  };
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
