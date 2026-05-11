import { describe, test, expect, beforeAll, afterAll } from "vitest";
import { Hono } from "hono";
import { mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

// Use a temp dir so tests don't pollute the real config
const tempDir = mkdtempSync(join(tmpdir(), "claude-assist-test-"));
process.env.CLAUDE_ASSIST_DATA_DIR = tempDir;

// Import after setting env var
const { configRoutes } = await import("../../routes/config.ts");

const app = new Hono();
app.route("/api/config", configRoutes);

afterAll(() => {
  rmSync(tempDir, { recursive: true, force: true });
});

describe("config routes", () => {
  describe("GET /api/config", () => {
    test("returns 200 with data containing indexPaths, embedding, server", async () => {
      const res = await app.request("/api/config");
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toBeDefined();
      expect(body.data.indexPaths).toBeInstanceOf(Array);
      expect(body.data.embedding).toBeDefined();
      expect(body.data.embedding.provider).toBe("local");
      expect(body.data.server).toBeDefined();
      expect(body.data.server.port).toBe(3100);
    });
  });

  describe("PATCH /api/config", () => {
    test("returns 200 with updated config", async () => {
      const res = await app.request("/api/config", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ embedding: { provider: "openai" } }),
      });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.embedding.provider).toBe("openai");
    });
  });
});
