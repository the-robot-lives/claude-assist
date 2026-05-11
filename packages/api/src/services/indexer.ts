import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, basename, dirname } from "node:path";
import {
  parseJsonlFile,
  isUserMessage,
  isAssistantMessage,
  isCustomTitle,
  extractTextContent,
  type BaseRecord,
  type UserMessage,
  type AssistantMessage,
  type CustomTitleRecord,
} from "@claude-assist/shared";
import { StorageService, type StoredMessage } from "./storage.ts";
import type { EmbeddingService } from "./embeddings.ts";

export interface IndexProgress {
  phase: "idle" | "scanning" | "indexing" | "embedding";
  current: number;
  total: number;
  currentFile?: string;
}

export class IndexerService {
  private storage: StorageService;
  private embeddings: EmbeddingService | null;
  private watchPaths: string[];
  private watcher: unknown = null;
  private debounceTimer: ReturnType<typeof setTimeout> | null = null;
  private fileModTimes = new Map<string, number>();
  private _progress: IndexProgress = { phase: "idle", current: 0, total: 0 };

  constructor(storage: StorageService, watchPaths: string[] = [], embeddings?: EmbeddingService) {
    this.storage = storage;
    this.embeddings = embeddings ?? null;
    this.watchPaths = watchPaths;
  }

  get progress(): IndexProgress {
    return { ...this._progress };
  }

  async indexAll(): Promise<{ indexed: number; errors: number; skipped: number }> {
    this.storage.setIndexStatus("indexing");
    this._progress = { phase: "scanning", current: 0, total: 0 };

    const allFiles: string[] = [];
    for (const watchPath of this.watchPaths) {
      allFiles.push(...findJsonlFiles(watchPath));
    }

    this._progress = { phase: "indexing", current: 0, total: allFiles.length };
    let indexed = 0;
    let errors = 0;
    let skipped = 0;

    for (let i = 0; i < allFiles.length; i++) {
      const filePath = allFiles[i];
      this._progress = { phase: "indexing", current: i + 1, total: allFiles.length, currentFile: basename(filePath) };
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

    this._progress = { phase: "idle", current: 0, total: 0 };
    this.storage.setIndexStatus("idle");
    return { indexed, errors, skipped };
  }

  async indexFile(filePath: string): Promise<void> {
    const content = readFileSync(filePath, "utf-8");
    const allRecords: Array<BaseRecord | CustomTitleRecord> = [];
    for (const record of parseJsonlFile(content)) {
      allRecords.push(record);
    }

    if (allRecords.length === 0) return;

    const contentRecords = allRecords.filter(
      (r): r is UserMessage | AssistantMessage =>
        isUserMessage(r) || isAssistantMessage(r),
    );

    // Extract the last custom-title metadata line (Claude Code appends these)
    let customTitle: string | null = null;
    for (const record of allRecords) {
      if (isCustomTitle(record) && record.customTitle) {
        customTitle = record.customTitle;
      }
    }

    if (contentRecords.length === 0) return;

    const firstRecord = contentRecords[0];
    const lastRecord = contentRecords[contentRecords.length - 1];
    const firstTimestamp = firstRecord.timestamp ?? new Date().toISOString();
    const lastTimestamp = lastRecord.timestamp ?? firstTimestamp;

    const conversationId = StorageService.generateId(filePath, firstTimestamp);
    const projectPath = decodeProjectPath(dirname(filePath));
    const generatedTitle = generateTitle(contentRecords);
    const title = customTitle ?? generatedTitle;

    const existing = await this.storage.getConversation(conversationId);
    await this.storage.upsertConversation({
      id: conversationId,
      projectPath,
      startedAt: firstTimestamp,
      updatedAt: lastTimestamp,
      messageCount: contentRecords.length,
      title,
      tags: existing?.tags,
      status: existing?.status,
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

  async scanPreview(): Promise<ScanPreview> {
    const projects: ScanProject[] = [];
    let totalFiles = 0;
    let totalNewFiles = 0;

    for (const watchPath of this.watchPaths) {
      const dirEntries = new Map<string, string[]>();

      const jsonlFiles = findJsonlFiles(watchPath);
      for (const filePath of jsonlFiles) {
        const dirName = basename(dirname(filePath));
        if (!dirEntries.has(dirName)) dirEntries.set(dirName, []);
        dirEntries.get(dirName)!.push(filePath);
      }

      for (const [dirName, files] of dirEntries) {
        const projectPath = decodeProjectPath(join(watchPath, dirName));
        let newCount = 0;
        for (const f of files) {
          const mtime = statSync(f).mtimeMs;
          const prev = this.fileModTimes.get(f);
          if (!prev || prev < mtime) newCount++;
        }
        projects.push({
          projectPath,
          encodedDir: dirName,
          fileCount: files.length,
          newOrChanged: newCount,
        });
        totalFiles += files.length;
        totalNewFiles += newCount;
      }
    }

    projects.sort((a, b) => b.fileCount - a.fileCount);

    const embeddingProvider = this.embeddings?.ready ? "local" : "none";
    const estimatedTokens = totalNewFiles * 2000;
    const estimatedCost = embeddingProvider === "local" ? 0 : estimatedTokens * 0.00001;

    return {
      watchPaths: this.watchPaths,
      projects,
      totalFiles,
      totalNewFiles,
      embeddingProvider,
      estimatedTokens,
      estimatedCost,
    };
  }
}

export interface ScanProject {
  projectPath: string;
  encodedDir: string;
  fileCount: number;
  newOrChanged: number;
}

export interface ScanPreview {
  watchPaths: string[];
  projects: ScanProject[];
  totalFiles: number;
  totalNewFiles: number;
  embeddingProvider: string;
  estimatedTokens: number;
  estimatedCost: number;
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

/**
 * Decode a Claude Code encoded directory name back to a real filesystem path.
 *
 * Claude Code encodes /Users/foo/noizu-infra as -Users-foo-noizu-infra,
 * which is ambiguous: -noizu-infra could mean /noizu/infra or /noizu-infra.
 *
 * Resolution: greedy left-to-right, preferring hyphenated directory names
 * (literal hyphens) over nested directories at each step. Falls back to
 * treating hyphens as path separators when neither exists.
 */
function decodeProjectPath(dirPath: string): string {
  const dirName = basename(dirPath);
  if (!dirName.startsWith("-")) return dirName;

  // Strip leading - (always represents root /)
  const segments = dirName.slice(1).split("-");
  if (segments.length === 0) return "/";

  return resolveEncodedSegments(segments);
}

function resolveEncodedSegments(segments: string[]): string {
  let resolved = "/";
  let i = 0;

  while (i < segments.length) {
    // Try greedily joining as many segments as possible with hyphens,
    // longest match first — prefer "noizu-infra-k8" over "noizu-infra" + "/k8"
    let matched = false;
    for (let end = segments.length; end > i + 1; end--) {
      const candidate = segments.slice(i, end).join("-");
      const candidatePath = join(resolved, candidate);
      if (existsSync(candidatePath)) {
        resolved = candidatePath;
        i = end;
        matched = true;
        break;
      }
    }

    if (!matched) {
      // No multi-segment hyphenated match — use single segment as directory
      resolved = join(resolved, segments[i]);
      i++;
    }
  }

  return resolved;
}

// Re-export for use by operations.ts
export { decodeProjectPath, resolveEncodedSegments };

function generateTitle(records: (UserMessage | AssistantMessage)[]): string {
  const firstUser = records.find((r): r is UserMessage => r.type === "user");
  if (!firstUser) return "Untitled conversation";

  const text = extractTextContent(firstUser);

  // Detect skill/command invocations: extract <command-name> and <command-args> tags
  const commandNameMatch = text.match(/<command-name>([^<]+)<\/command-name>/);
  if (commandNameMatch) {
    const commandName = commandNameMatch[1].trim();
    const argsMatch = text.match(/<command-args>([^<]*)<\/command-args>/);
    const args = argsMatch ? argsMatch[1].trim() : "";
    const title = args ? `${commandName} ${args}` : commandName;
    if (title.length <= 80) return title;
    return title.slice(0, 77) + "...";
  }

  const firstLine = text.split("\n")[0].trim();
  if (firstLine.length <= 80) return firstLine;
  return firstLine.slice(0, 77) + "...";
}
