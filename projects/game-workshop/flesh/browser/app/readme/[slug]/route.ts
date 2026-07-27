import { readFile } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";
import { loadCatalog } from "../../../lib/catalog";

type Params = {
  params: Promise<{ slug: string }>;
};

export async function GET(_request: Request, { params }: Params) {
  const { slug } = await params;
  const catalog = await loadCatalog();
  const game = catalog.games.find((entry) => entry.slug === slug);

  if (!game) {
    return new NextResponse("Unknown backlog entry.", { status: 404 });
  }

  const readmePath = path.resolve(process.cwd(), "..", game.source);
  const fleshRoot = path.resolve(process.cwd(), "..");

  if (!readmePath.startsWith(fleshRoot)) {
    return new NextResponse("Invalid backlog entry.", { status: 400 });
  }

  const markdown = await readFile(readmePath, "utf8");

  return new NextResponse(markdown, {
    headers: {
      "Content-Type": "text/markdown; charset=utf-8"
    }
  });
}
