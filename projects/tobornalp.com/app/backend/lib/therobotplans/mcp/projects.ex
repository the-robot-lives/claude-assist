defmodule Therobotplans.MCP.Projects do
  use Noizu.MCP.Server,
    name: "tobornalp_projects",
    version: "0.1.0",
    instructions:
      "Project management domain — list, get, create, and update projects within an organization."

  tool(Therobotplans.MCP.Projects.Tools.Overview, category: "Projects")
  tool(Therobotplans.MCP.Projects.Tools.ProjectCreate, category: "Projects")
  tool(Therobotplans.MCP.Projects.Tools.ProjectGet, category: "Projects")
  tool(Therobotplans.MCP.Projects.Tools.ProjectUpdate, category: "Projects")
  tool(Therobotplans.MCP.Projects.Tools.ProjectList, category: "Projects")

  tool(Therobotplans.Tools.ToolSummary, category: "Discovery")
  tool(Therobotplans.Tools.ToolSearch, category: "Discovery")
  tool(Therobotplans.Tools.ToolDefinition, category: "Discovery")
  tool(Therobotplans.Tools.ToolCall, category: "Discovery")
  tool(Therobotplans.Tools.ToolHelp, category: "Discovery")
end
