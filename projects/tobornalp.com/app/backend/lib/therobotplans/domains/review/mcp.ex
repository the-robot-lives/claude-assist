defmodule Therobotplans.Domains.Review.MCP do
  @moduledoc """
  Code/content review MCP server — create reviews over artifact revisions, leave
  overlay annotations, compile feedback, issue a verdict.

  NOTE: the review-specific tools below mirror NPL's
  `NoizuPromptLingua.Domains.Review.Tools.*` (overview/create/get/comment/overlay/
  complete/compile/attach). Those tool modules are NOT yet ported — once they are
  added under `Therobotplans.Domains.Review.Tools.*`, uncomment the `tool/2` lines
  and this server is ready to register in `Therobotplans.MCPServers`. Only the
  Discovery tools (which already exist under `Therobotplans.Tools.*`) are wired
  here so this module compiles standalone.
  """
  use Noizu.MCP.Server,
    name: "tobornalp_review",
    version: "0.1.0",
    instructions: "Code review domain — create reviews, add comments and overlays, compile feedback."

  # tool Therobotplans.Domains.Review.Tools.Overview, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewCreate, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewGet, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewComment, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewOverlay, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewComplete, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewCompile, category: "Review"
  # tool Therobotplans.Domains.Review.Tools.ReviewAttach, category: "Review"

  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
