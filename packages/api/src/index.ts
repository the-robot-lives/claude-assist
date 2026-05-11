import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { serve } from "@hono/node-server";
import { join } from "node:path";
import { homedir } from "node:os";
import { createConversationRoutes } from "./routes/conversations.ts";
import { createSearchRoutes } from "./routes/search.ts";
import { createDatasetRoutes } from "./routes/datasets.ts";
import { configRoutes } from "./routes/config.ts";
import { createIndexRoutes } from "./routes/index-routes.ts";
import { StorageService } from "./services/storage.ts";
import { IndexerService } from "./services/indexer.ts";
import { SearchService } from "./services/search.ts";
import { EmbeddingService } from "./services/embeddings.ts";

const dataDir = process.env.CLAUDE_ASSIST_DATA_DIR ?? join(homedir(), ".claude-assist");
const dbPath = join(dataDir, "claude-assist.db");

const defaultWatchPaths = [join(homedir(), ".claude", "projects")];
const watchPaths = process.env.CLAUDE_ASSIST_WATCH_PATHS
  ? process.env.CLAUDE_ASSIST_WATCH_PATHS.split(":")
  : defaultWatchPaths;

const embeddings = new EmbeddingService();
const storage = new StorageService(dbPath);
const indexer = new IndexerService(storage, watchPaths, embeddings);
const searchService = new SearchService(storage, embeddings);

const app = new Hono();

app.use("*", logger());
app.use("*", cors({ origin: "http://localhost:5173" }));

app.get("/api/health", (c) => c.json({ status: "ok" }));

app.route("/api/conversations", createConversationRoutes(storage));
app.route("/api/search", createSearchRoutes(searchService));
app.route("/api/datasets", createDatasetRoutes(storage));
app.route("/api/config", configRoutes);
app.route("/api/index", createIndexRoutes(indexer));

const port = Number(process.env.PORT) || 3100;

async function start() {
  const { mkdirSync } = await import("node:fs");
  mkdirSync(dataDir, { recursive: true });

  await storage.initialize();
  console.log(`Database initialized at ${dbPath}`);

  embeddings.initialize().then(() => {
    if (embeddings.ready) {
      console.log("Embedding model ready — semantic search enabled");
    }
  });

  serve({ fetch: app.fetch, port }, async () => {
    console.log(`claude-assist api listening on http://localhost:${port}`);
    console.log(`Watching: ${watchPaths.join(", ")}`);

    const stats = await storage.getStats();
    if (stats.conversationCount === 0) {
      console.log("No conversations indexed — running initial index...");
      indexer.indexAll().then((result) => {
        console.log(`Initial index: ${result.indexed} indexed, ${result.errors} errors, ${result.skipped} skipped`);
      });
    }

    if (process.env.CLAUDE_ASSIST_WATCH !== "false") {
      indexer.watch();
    }
  });
}

start().catch((err) => {
  console.error("Failed to start:", err);
  process.exit(1);
});

export { app, storage, indexer, searchService };
