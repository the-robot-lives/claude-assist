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

  # Console/ops surface (API contract Phase D) — same internal API as the HTTP endpoints.
  tool TheRobotRemembers.MCP.Tools.MemoryArchive, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.MemoryRestore, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.GraphSubgraph, category: "Graph"
  tool TheRobotRemembers.MCP.Tools.EdgeSetWeight, category: "Graph"
  tool TheRobotRemembers.MCP.Tools.MemorySet, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.RecallPreview, category: "Memory"
  tool TheRobotRemembers.MCP.Tools.AgentMoodGet, category: "Agent"
  tool TheRobotRemembers.MCP.Tools.AgentMoodSet, category: "Agent"
  tool TheRobotRemembers.MCP.Tools.CompartmentsList, category: "Memory"

  # Phase B — graph traversal seam (ADR-006): path-explanation surface.
  tool TheRobotRemembers.MCP.Tools.GraphExplainPath, category: "Graph"
end
