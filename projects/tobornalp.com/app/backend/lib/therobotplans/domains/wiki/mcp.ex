defmodule Therobotplans.Domains.Wiki.MCP do
  @moduledoc """
  MCP server for the Wiki domain. NOT registered in mcp_servers.ex — mount it
  there (and add the SSE child to application.ex) to expose the tools.

  Ported from NPL Domains.Wiki.MCP (tobor_wiki → tobornalp_wiki).
  """
  use Noizu.MCP.Server,
    name: "tobornalp_wiki",
    version: "0.1.0",
    instructions: "Wiki domain — manage spaces, pages, comments, attachments, and reactions."

  tool Therobotplans.Domains.Wiki.Tools.Overview, category: "Wiki"

  tool Therobotplans.Domains.Wiki.Tools.SpaceList, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.SpaceGet, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.SpaceCreate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.SpaceUpdate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.SpaceDelete, category: "Wiki"

  tool Therobotplans.Domains.Wiki.Tools.PageList, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.PageGet, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.PageCreate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.PageUpdate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.PageDelete, category: "Wiki"

  tool Therobotplans.Domains.Wiki.Tools.CommentList, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.CommentCreate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.CommentDelete, category: "Wiki"

  tool Therobotplans.Domains.Wiki.Tools.AttachmentList, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.AttachmentCreate, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.AttachmentDelete, category: "Wiki"

  tool Therobotplans.Domains.Wiki.Tools.ReactionList, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.ReactionAdd, category: "Wiki"
  tool Therobotplans.Domains.Wiki.Tools.ReactionRemove, category: "Wiki"

  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
