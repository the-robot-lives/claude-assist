import { NextResponse } from "next/server";
import { demoDocument } from "@/lib/holograph/fixture";

interface RouteContext {
  params: Promise<{ id: string }>;
}

export async function GET(_request: Request, context: RouteContext) {
  const { id } = await context.params;

  if (id !== demoDocument.id) {
    return NextResponse.json({ error: "Document not found" }, { status: 404 });
  }

  return NextResponse.json({ data: demoDocument });
}
