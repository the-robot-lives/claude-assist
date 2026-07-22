import { NextResponse } from "next/server";
import { demoDocument } from "@/lib/holograph/fixture";

interface RouteContext {
  params: Promise<{ id: string }>;
}

export async function POST(request: Request, context: RouteContext) {
  const { id } = await context.params;

  if (id !== demoDocument.id) {
    return NextResponse.json(
      { error: { code: "not_found", message: "Document not found" } },
      { status: 404 },
    );
  }

  const body = await request.json().catch(() => ({}));
  const patchId = typeof body?.patchId === "string" ? body.patchId : "local-patch";

  return NextResponse.json({
    data: {
      patchId,
      documentId: id,
      version: demoDocument.version + 1,
      status: "applied",
    },
    meta: {
      source: "fixture",
      persistence: "pending Phoenix HoloGraph.Docs patch batch storage",
    },
  });
}
