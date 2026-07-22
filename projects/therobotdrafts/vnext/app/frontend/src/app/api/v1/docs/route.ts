import { NextResponse } from "next/server";
import { listDocuments } from "@/lib/holograph/fixture";
import { isGraphDocument, normalizeGraphDocument } from "@/lib/holograph/document-io";

export function GET() {
  return NextResponse.json({ data: listDocuments() });
}

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));
  if (isGraphDocument(body?.document)) {
    const document = normalizeGraphDocument(body.document);
    return NextResponse.json(
      {
        data: {
          id: document.id,
          slug: document.slug,
          title: document.title,
          version: document.version,
          updatedAt: document.updatedAt,
          summary: document.summary,
          nodeCount: document.nodes.length,
          edgeCount: document.edges.length,
        },
        meta: {
          imported: true,
          source: "request-document",
          persistence: "browser-local until Phoenix storage is enabled",
        },
      },
      { status: 201 },
    );
  }

  return NextResponse.json(
    {
      data: listDocuments()[0],
      meta: {
        imported: false,
        source: "example-document",
        persistence: "browser-local until Phoenix storage is enabled",
      },
    },
    { status: 201 },
  );
}
