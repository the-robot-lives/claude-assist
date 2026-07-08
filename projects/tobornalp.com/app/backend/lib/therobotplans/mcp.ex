defmodule Therobotplans.MCP do
  @moduledoc """
  Root MCP server. Aggregates the domain tools alongside the Discovery tools so
  a single endpoint can browse and invoke everything via ToolSummary / ToolCall.

  Add new domains' tools here (or mount them on their own subdomain) as they
  come online across the implementation phases.
  """

  use Noizu.MCP.Server,
    name: "therobotplans",
    version: "0.1.0",
    instructions:
      "tobornalp (therobotplans) MCP server. Use the Discovery tools (ToolSummary, ToolSearch, " <>
        "ToolDefinition, ToolHelp, ToolCall) to find and invoke all available tools."

  # Projects
  tool Therobotplans.MCP.Projects.Tools.Overview, category: "Projects"
  tool Therobotplans.MCP.Projects.Tools.ProjectCreate, category: "Projects"
  tool Therobotplans.MCP.Projects.Tools.ProjectGet, category: "Projects"
  tool Therobotplans.MCP.Projects.Tools.ProjectUpdate, category: "Projects"
  tool Therobotplans.MCP.Projects.Tools.ProjectList, category: "Projects"

  # Discovery
  tool Therobotplans.Tools.ToolSummary
  tool Therobotplans.Tools.ToolSearch
  tool Therobotplans.Tools.ToolDefinition
  tool Therobotplans.Tools.ToolCall
  tool Therobotplans.Tools.ToolHelp
end
