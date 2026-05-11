import { Hono } from "hono";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { homedir } from "node:os";
import type { AppConfig } from "@claude-assist/shared";

function getConfigPath(): string {
  const configDir = process.env.CLAUDE_ASSIST_DATA_DIR ?? join(homedir(), ".claude-assist");
  return join(configDir, "config.json");
}

function loadConfig(): AppConfig {
  const defaults: AppConfig = {
    indexPaths: [join(homedir(), ".claude", "projects")],
    embedding: { provider: "local", model: "all-MiniLM-L6-v2" },
    server: { port: 3100, host: "localhost" },
  };

  try {
    if (existsSync(getConfigPath())) {
      const raw = JSON.parse(readFileSync(getConfigPath(), "utf-8"));
      return { ...defaults, ...raw };
    }
  } catch {
    // Fall through to defaults
  }
  return defaults;
}

function saveConfig(config: AppConfig): void {
  const configFile = getConfigPath();
  mkdirSync(dirname(configFile), { recursive: true });
  writeFileSync(configFile, JSON.stringify(config, null, 2), "utf-8");
}

export const configRoutes = new Hono();

configRoutes.get("/", async (c) => {
  const config = loadConfig();
  return c.json({ data: config });
});

configRoutes.patch("/", async (c) => {
  const current = loadConfig();
  const updates = await c.req.json() as Partial<AppConfig>;

  if (updates.indexPaths) current.indexPaths = updates.indexPaths;
  if (updates.embedding) current.embedding = { ...current.embedding, ...updates.embedding };
  if (updates.server) current.server = { ...current.server, ...updates.server };
  if (updates.llm) current.llm = { ...current.llm, ...updates.llm };

  saveConfig(current);
  return c.json({ data: current });
});
