import walkingSkeleton from "./fixtures/holograph-m0-m1-walking-skeleton.graph-document.json";
import type { GraphDocument } from "./types";

export const demoDocument = walkingSkeleton as GraphDocument;

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
