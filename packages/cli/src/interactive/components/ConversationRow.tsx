import React from "react";
import { Box, Text } from "ink";

interface ConversationRowProps {
  id: string;
  title: string;
  projectPath: string;
  messageCount?: number;
  updatedAt?: string;
  status?: string;
  snippet?: string;
  isCursor: boolean;
}

export function ConversationRow({
  id,
  title,
  projectPath,
  messageCount,
  updatedAt,
  status,
  snippet,
  isCursor,
}: ConversationRowProps) {
  const shortProject = projectPath.split("/").filter(Boolean).slice(-2).join("/");
  const dateStr = updatedAt ? new Date(updatedAt).toLocaleDateString() : "";

  return (
    <Box flexDirection="column">
      <Text inverse={isCursor}>
        <Text color={isCursor ? "cyan" : undefined}>
          {isCursor ? "▸ " : "  "}
        </Text>
        <Text dimColor>{id.slice(0, 8)}</Text>
        {" "}
        <Text color="cyan" dimColor>[{shortProject}]</Text>
        {" "}
        <Text bold={isCursor}>
          {title.startsWith("/") ? (
            <><Text color="cyan">{title.split(" ")[0]}</Text> {title.split(" ").slice(1).join(" ")}</>
          ) : title}
        </Text>
        {messageCount != null && <Text dimColor> ({messageCount} msgs)</Text>}
        {dateStr && <Text dimColor> {dateStr}</Text>}
        {status && status !== "active" && <Text dimColor> [{status}]</Text>}
      </Text>
      {snippet && (
        <Text dimColor wrap="truncate-end">
          {"    "}{snippet.replace(/<<</g, "").replace(/>>>/g, "")}
        </Text>
      )}
    </Box>
  );
}
