import { createHash } from "node:crypto";
import type { StorageService } from "./storage.ts";

export class OperationsService {
  constructor(private storage: StorageService) {}

  async archive(conversationId: string): Promise<void> {
    const conv = await this.storage.getConversation(conversationId);
    if (!conv) throw new Error("Conversation not found");
    await this.storage.upsertConversation({
      ...convToUpsert(conv),
      status: "archived",
    });
  }

  async tag(conversationId: string, tags: string[]): Promise<void> {
    const conv = await this.storage.getConversation(conversationId);
    if (!conv) throw new Error("Conversation not found");
    await this.storage.upsertConversation({
      ...convToUpsert(conv),
      tags,
    });
  }

  async clone(conversationId: string): Promise<string> {
    const conv = await this.storage.getConversation(conversationId);
    if (!conv) throw new Error("Conversation not found");
    const newId = createHash("sha256").update(`${conv.id}:clone:${Date.now()}`).digest("hex").slice(0, 16);
    await this.storage.upsertConversation({
      ...convToUpsert(conv),
      id: newId,
      title: `${conv.title} (copy)`,
    });
    const messages = await this.storage.getMessages(conversationId);
    const clonedMessages = messages.map((m) => ({ ...m, conversationId: newId }));
    await this.storage.insertMessages(newId, clonedMessages);
    return newId;
  }

  async rehome(conversationId: string, targetProject: string): Promise<void> {
    const conv = await this.storage.getConversation(conversationId);
    if (!conv) throw new Error("Conversation not found");
    await this.storage.upsertConversation({
      ...convToUpsert(conv),
      projectPath: targetProject,
    });
  }
}

function convToUpsert(conv: { id: string; projectPath: string; startedAt: Date; updatedAt: Date; messageCount: number; title: string; summary: string | null; tags: string[]; status: string; sourcePath: string }) {
  return {
    id: conv.id,
    projectPath: conv.projectPath,
    startedAt: conv.startedAt.toISOString(),
    updatedAt: conv.updatedAt.toISOString(),
    messageCount: conv.messageCount,
    title: conv.title,
    summary: conv.summary,
    tags: conv.tags,
    status: conv.status,
    sourcePath: conv.sourcePath,
  };
}
