defmodule Therobotplans.Domains.Personal.MCP do
  @moduledoc """
  Personal-todos MCP domain server (WS-A). Read-path for agents (US-018 planner
  triage). Inert until registered: this module is NOT yet in `application.ex`
  children nor the router MCP scopes / `MCPServers` catalog — those are shared
  WS-L touchpoints, reported as an interface ticket rather than edited here.
  """
  use Noizu.MCP.Server,
    name: "tobornalp_personal",
    version: "0.1.0",
    instructions:
      "Personal todos domain — a user's private todo list (due dates, tags, recurrence). Personal items are strictly owner-scoped."

  tool(Therobotplans.Domains.Personal.Tools.ItemList, category: "Personal")

  # Discovery (mirrors the items domain server).
  tool(Therobotplans.Tools.ToolSummary, category: "Discovery")
  tool(Therobotplans.Tools.ToolSearch, category: "Discovery")
  tool(Therobotplans.Tools.ToolDefinition, category: "Discovery")
  tool(Therobotplans.Tools.ToolCall, category: "Discovery")
  tool(Therobotplans.Tools.ToolHelp, category: "Discovery")
end
