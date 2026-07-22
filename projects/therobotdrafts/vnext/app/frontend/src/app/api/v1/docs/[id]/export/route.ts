import { NextResponse } from "next/server";
import { demoDocument } from "@/lib/holograph/fixture";
import {
  exportCodeSkeleton,
  exportDot,
  exportMermaid,
  exportPlantUml,
  isGraphDocument,
  normalizeGraphDocument,
} from "@/lib/holograph/document-io";
import type { GraphDocument } from "@/lib/holograph/types";

interface RouteContext {
  params: Promise<{ id: string }>;
}

function exportedBody(document: GraphDocument, format: string) {
  if (format === "json") return JSON.stringify(document, null, 2);
  if (format === "mermaid") return exportMermaid(document);
  if (format === "dot") return exportDot(document);
  if (format === "code") return exportCodeSkeleton(document);
  return exportPlantUml(document);
}

export async function POST(request: Request, context: RouteContext) {
  const { id } = await context.params;
  const requestBody = await request.json().catch(() => ({}));
  const document = isGraphDocument(requestBody?.document)
    ? normalizeGraphDocument(requestBody.document)
    : id === demoDocument.id
      ? demoDocument
      : null;

  if (!document) {
    return NextResponse.json(
      { error: { code: "not_found", message: "Document not found" } },
      { status: 404 },
    );
  }

  const format = typeof requestBody?.format === "string" ? requestBody.format : "plantuml";

  return NextResponse.json({
    data: {
      documentId: id,
      format,
      body: exportedBody(document, format),
    },
    meta: {
      source: isGraphDocument(requestBody?.document) ? "request-document" : "example-document",
      exporter: "TRD browser-local roundtrip",
    },
  });
}
