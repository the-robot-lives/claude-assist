import type { BaseRecord, UserMessage, AssistantMessage } from "../types/index.ts";

export function parseJsonlLine(line: string): BaseRecord {
  return JSON.parse(line) as BaseRecord;
}

export function* parseJsonlFile(content: string): Generator<BaseRecord> {
  for (const line of content.split("\n")) {
    if (line.trim()) {
      yield parseJsonlLine(line);
    }
  }
}

export function isUserMessage(record: BaseRecord): record is UserMessage {
  return record.type === "user";
}

export function isAssistantMessage(record: BaseRecord): record is AssistantMessage {
  return record.type === "assistant";
}

export function extractTextContent(message: UserMessage | AssistantMessage): string {
  const content = message.message.content;
  if (typeof content === "string") return content;
  return content
    .filter((block) => block.type === "text")
    .map((block) => block.text ?? "")
    .join("\n");
}
