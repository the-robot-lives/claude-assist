import React from "react";
import { Box, Text } from "ink";
import { SearchCommand } from "./commands/search.js";
import { ListCommand } from "./commands/list.js";
import { ShowCommand } from "./commands/show.js";
import { IndexCommand } from "./commands/index.js";

interface AppProps {
  command: string;
  args: string[];
}

export function App({ command, args }: AppProps) {
  switch (command) {
    case "search":
      return <SearchCommand query={args.join(" ")} />;
    case "list":
      return <ListCommand args={args} />;
    case "show":
      return <ShowCommand id={args[0]} />;
    case "index":
      return <IndexCommand />;
    case "serve":
      return (
        <Box flexDirection="column">
          <Text color="cyan">Starting claude-assist server...</Text>
          <Text dimColor>API: http://localhost:3100</Text>
          <Text dimColor>Web: http://localhost:5173</Text>
        </Box>
      );
    case "interactive":
      return (
        <Box flexDirection="column" padding={1}>
          <Text bold color="cyan">claude-assist</Text>
          <Text dimColor>Search, browse, and extract from Claude Code conversations</Text>
          <Box marginTop={1} flexDirection="column">
            <Text>Commands:</Text>
            <Text>  <Text color="cyan">search</Text>  {"  "}Search conversations</Text>
            <Text>  <Text color="cyan">list</Text>    {"  "}List conversations</Text>
            <Text>  <Text color="cyan">show</Text>    {"  "}View a conversation</Text>
            <Text>  <Text color="cyan">edit</Text>    {"  "}Edit a conversation thread</Text>
            <Text>  <Text color="cyan">convert</Text> {"  "}Extract agent/skill/command</Text>
            <Text>  <Text color="cyan">dataset</Text> {"  "}Manage fine-tuning datasets</Text>
            <Text>  <Text color="cyan">serve</Text>   {"  "}Start API + web UI</Text>
            <Text>  <Text color="cyan">index</Text>   {"  "}Rebuild search index</Text>
          </Box>
        </Box>
      );
    default:
      return <Text color="red">Unknown command: {command}</Text>;
  }
}
