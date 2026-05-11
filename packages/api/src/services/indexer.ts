import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, basename, dirname } from "node:path";
import {
  parseJsonlFile,
  isUserMessage,
  isAssistantMessage,
  extractTextContent,
  type BaseRecord,
  type UserMessage,
  type AssistantMessage,
} from "@claude-assist/shared";
import { StorageService, type StoredMessage } from "./storage.ts";
import type { EmbeddingService } from "./embeddings.ts";

export class IndexerService {
  private storage: StorageService;
  private embeddings: EmbeddingService | null;
  private watchPaths: string[];
  private watcher: unknown = null;
  private debounceTimer: ReturnType<typeof setTimeout> | null = null;
  private fileModTimes = new Map<string, number>();

  constructor(storage: StorageService, watchPaths: string[] = [], embeddings?: EmbeddingService) {
    this.storage = storage;
    this.embeddings = embeddings ?? null;
    this.watchPaths = watchPaths;
  }

  async indexAll(): Promise<{ indexed: number; errors: number; skipped: number }> {
    this.storage.setIndexStatus("indexing");
    let indexed = 0;
    let errors = 0;
    let skipped = 0;

    for (const watchPath of this.watchPaths) {
      const jsonlFiles = findJsonlFiles(watchPath);
      for (const filePath of jsonlFiles) {
        try {
          const mtime = statSync(filePath).mtimeMs;
          const prevMtime = this.fileModTimes.get(filePath);
          if (prevMtime && prevMtime >= mtime) {
            skipped++;
            continue;
          }
          await this.indexFile(filePath);
          this.fileModTimes.set(filePath, mtime);
          indexed++;
        } catch (e) {
          errors++;
          console.error(`Failed to index ${filePath}:`, e instanceof Error ? e.message : e);
        }
      }
    }

    this.storage.setIndexStatus("idle");
    return { indexed, errors, skipped };
  }

  async indexFile(filePath: string): Promise<void> {
    const content = readFileSync(filePath, "utf-8");
    const records: BaseRecord[] = [];
    for (const record of parseJsonlFile(content)) {
      records.push(record);
    }

    if (records.length === 0) return;

    const contentRecords = records.filter(
      (r): r is UserMessage | AssistantMessage =>
        isUserMessage(r) || isAssistantMessage(r),
    );

    if (contentRecords.length === 0) return;

    const firstRecord = contentRecords[0];
    const lastRecord = contentRecords[contentRecords.length - 1];
    const firstTimestamp = firstRecord.timestamp ?? new Date().toISOString();
    const lastTimestamp = lastRecord.timestamp ?? firstTimestamp;

    const conversationId = StorageService.generateId(filePath, firstTimestamp);
    const projectPath = decodeProjectPath(dirname(filePath));
    const title = generateTitle(contentRecords);

    await this.storage.upsertConversation({
      id: conversationId,
      projectPath,
      startedAt: firstTimestamp,
      updatedAt: lastTimestamp,
      messageCount: contentRecords.length,
      title,
      sourcePath: filePath,
    });

    const messages: StoredMessage[] = contentRecords.map((record) => ({
      conversationId,
      role: record.type === "user" ? "user" : "assistant",
      content: extractTextContent(record),
      timestamp: record.timestamp ?? "",
    }));

    await this.storage.insertMessages(conversationId, messages);

    if (this.embeddings?.ready && this.storage.vecAvailable) {
      try {
        const summaryText = messages
          .slice(0, 10)
          .map((m) => m.content)
          .join("\n")
          .slice(0, 2000);
        const embedding = await this.embeddings.embed(summaryText);
        await this.storage.upsertVector(conversationId, embedding);
      } catch {
        // Non-fatal: skip embedding for this conversation
      }
    }
  }

  async watch(): Promise<void> {
    try {
      const chokidar = await import("chokidar");
      const watcher = chokidar.watch(
        this.watchPaths.map((p) => join(p, "**/*.jsonl")),
        { ignoreInitial: true, awaitWriteFinish: { stabilityThreshold: 1000 } },
      );

      watcher.on("add", (path: string) => this.debouncedIndex(path));
      watcher.on("change", (path: string) => this.debouncedIndex(path));

      this.watcher = watcher;
      console.log("File watcher started");
    } catch (err) {
      console.warn("Failed to start file watcher:", err instanceof Error ? err.message : err);
    }
  }

  private debouncedIndex(filePath: string): void {
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(async () => {
      try {
        await this.indexFile(filePath);
        this.fileModTimes.set(filePath, Date.now());
        console.log(`Re-indexed: ${basename(filePath)}`);
      } catch (e) {
        console.error(`Watch re-index failed for ${filePath}:`, e instanceof Error ? e.message : e);
      }
    }, 2000);
  }

  async stopWatch(): Promise<void> {
    if (this.watcher && typeof (this.watcher as { close: () => Promise<void> }).close === "function") {
      await (this.watcher as { close: () => Promise<void> }).close();
      this.watcher = null;
    }
  }

  getStatus(): { status: string; lastIndexed: string | null; conversationCount: number } {
    return this.storage.getIndexStatus();
  }
}

function findJsonlFiles(dir: string): string[] {
  const results: string[] = [];
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        results.push(...findJsonlFiles(fullPath));
      } else if (entry.name.endsWith(".jsonl")) {
        results.push(fullPath);
      }
    }
  } catch {
    // Skip directories we can't read
  }
  return results;
}

function decodeProjectPath(dirPath: string): string {
  const dirName = basename(dirPath);
  if (dirName.startsWith("-")) {
    return dirName.replace(/^-/, "/").replace(/-/g, "/");
  }
  return dirName;
}

function generateTitle(records: (UserMessage | AssistantMessage)[]): string {
  const firstUser = records.find((r): r is UserMessage => r.type === "user");
  if (!firstUser) return "Untitled conversation";

  const text = extractTextContent(firstUser);
  const firstLine = text.split("\n")[0].trim();
  if (firstLine.length <= 80) return firstLine;
  return firstLine.slice(0, 77) + "...";
}
