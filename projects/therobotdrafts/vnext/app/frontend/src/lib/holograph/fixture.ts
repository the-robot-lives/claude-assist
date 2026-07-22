import walkingSkeleton from "./fixtures/holograph-m0-m1-walking-skeleton.graph-document.json";
import type { GraphDocument, PatchOperation } from "./types";

export const demoDocument = walkingSkeleton as GraphDocument;

export const demoPatches: PatchOperation[] = [
  {
    id: "p-001",
    type: "add_node",
    targetId: "renderer-bridge",
    label: "Add minimap overlay to renderer bridge",
    status: "applied",
  },
  {
    id: "p-002",
    type: "connect",
    targetId: "focus-command",
    label: "Link focus command to patch review queue",
    status: "review",
  },
  {
    id: "p-003",
    type: "rename",
    targetId: "scene-layout",
    label: "Rename sphere pack seam to ILayout",
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
