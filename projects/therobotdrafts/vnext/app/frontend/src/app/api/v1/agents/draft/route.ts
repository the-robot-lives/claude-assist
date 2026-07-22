import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));
  const prompt = typeof body?.prompt === "string" ? body.prompt : "";
  const targetId = typeof body?.targetId === "string" ? body.targetId : "uml-scene";

  return NextResponse.json({
    data: {
      id: "draft-local-001",
      status: "proposed",
      documentId: "trd-demo",
      baseVersion: 3,
      operations: [
        {
          id: "op-add-note",
          type: "add_node",
          targetId,
          label: prompt.trim() ? `Draft from prompt: ${prompt.trim().slice(0, 72)}` : "Draft review note",
          payload: {
            kind: "class",
            status: "review",
          },
        },
      ],
    },
    meta: {
      source: "local-draft-shim",
      nextBackend: "HoloGraph.Agents",
    },
  });
}
