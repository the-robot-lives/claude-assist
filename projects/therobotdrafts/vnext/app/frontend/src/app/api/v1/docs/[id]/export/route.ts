import { NextResponse } from "next/server";
import { demoDocument } from "@/lib/holograph/fixture";

interface RouteContext {
  params: Promise<{ id: string }>;
}

export async function POST(_request: Request, context: RouteContext) {
  const { id } = await context.params;

  if (id !== demoDocument.id) {
    return NextResponse.json(
      { error: { code: "not_found", message: "Document not found" } },
      { status: 404 },
    );
  }

  const plantUml = [
    "@startuml",
    "title The Robot Draft 3D UML vnext workspace",
    ...demoDocument.nodes.map((node) => `component "${node.label}" as ${node.id.replaceAll("-", "_")}`),
    ...demoDocument.edges.map(
      (edge) => `${edge.sourceId.replaceAll("-", "_")} --> ${edge.targetId.replaceAll("-", "_")} : ${edge.label}`,
    ),
    "@enduml",
  ].join("\n");

  return NextResponse.json({
    data: {
      documentId: id,
      format: "plantuml",
      body: plantUml,
    },
    meta: {
      source: "fixture",
      exporter: "M5 placeholder",
    },
  });
}
