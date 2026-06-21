defmodule TheRobotRemembers.MCP do
  @moduledoc """
  MCP server for the associative memory engine ("tobor_memory").

  Phase 0 surface: the three core verbs — `remember`, `recall`, `recall_by_emotion`.
  Mounted as a Streamable-HTTP endpoint at `/mcp` (see router) and runnable over stdio via
  `mix trr.mcp.stdio`. Auth is dev-open in Phase 0; JWT-from-API-key (NPL pattern) is a
  follow-up. Discovery tools and the hidden/ops surface arrive in later phases.
  """
  use Noizu.MCP.Server,
    name: "tobor_memory",
    version: "0.1.0",
    instructions:
      "Associative memory for AI agents. Capture a memory with four facets — content, " <>
      "context (what you were doing), reflection (how you felt), tangent (what it evokes) — " <>
      "and recall by text (recall) or by a target emotional state (recall_by_emotion). " <>
      "Recall blends semantic, emotional, and associative paths."

  tool TheRobotRemembers.MCP.Tools.Remember, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.Recall, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.RecallByEmotion, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.Reinforce, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.Denforce, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.MemoryAssociations, category: "Memory"
end
