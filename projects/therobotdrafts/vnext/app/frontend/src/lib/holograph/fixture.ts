import walkingSkeleton from "./fixtures/holograph-m0-m1-walking-skeleton.graph-document.json";
import type { GraphDocument, PatchOperation } from "./types";

export const demoDocument = walkingSkeleton as GraphDocument;

export const demoPatches: PatchOperation[] = [
  {
    id: "p-001",
    type: "add_node",
    targetId: "uml-scene",
    label: "Add orientation gizmo to the 3D scene",
    status: "applied",
  },
  {
    id: "p-002",
    type: "connect",
    targetId: "camera-rig",
    label: "Link frame selected command to the camera rig",
    status: "review",
  },
  {
    id: "p-003",
    type: "rename",
    targetId: "node-shape",
    label: "Rename shape contract to IRenderer3D",
    status: "queued",
  },
];

export function listDocuments() {
  return [
    {
      id: demoDocument.id,
      slug: demoDocument.slug,
      title: demoDocument.title,
      version: demoDocument.version,
      updatedAt: demoDocument.updatedAt,
      summary: demoDocument.summary,
      nodeCount: demoDocument.nodes.length,
      edgeCount: demoDocument.edges.length,
    },
  ];
}
