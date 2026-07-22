import { NextResponse } from "next/server";
import { listDocuments } from "@/lib/holograph/fixture";

export function GET() {
  return NextResponse.json({ data: listDocuments() });
}

export async function POST() {
  return NextResponse.json(
    {
      data: listDocuments()[0],
      meta: {
        imported: true,
        source: "fixture",
        nextBackend: "Phoenix HoloGraph.Docs persistence",
      },
    },
    { status: 201 },
  );
}
