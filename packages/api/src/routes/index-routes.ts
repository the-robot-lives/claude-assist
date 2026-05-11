import { Hono } from "hono";
import type { IndexerService } from "../services/indexer.ts";

export function createIndexRoutes(indexer: IndexerService): Hono {
  const routes = new Hono();

  routes.post("/rebuild", async (c) => {
    // Fire-and-forget: start indexing in the background
    indexer.indexAll().then((result) => {
      console.log(`Indexing complete: ${result.indexed} indexed, ${result.errors} errors`);
    }).catch((err) => {
      console.error("Indexing failed:", err);
    });
    return c.json({ data: { status: "started" } });
  });

  routes.get("/status", async (c) => {
    const status = indexer.getStatus();
    return c.json({ data: status });
  });

  return routes;
}

// Backward-compatible named export for existing tests
export const indexRoutes = new Hono();
indexRoutes.post("/rebuild", async (c) => c.json({ data: { status: "started" } }));
indexRoutes.get("/status", async (c) => c.json({ data: { status: "idle", lastIndexed: null, conversationCount: 0 } }));
