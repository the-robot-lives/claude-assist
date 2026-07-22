defmodule Therobotplans.Domains.Artifacts.MCP do
  use Noizu.MCP.Server,
    name: "tobornalp_artifacts",
    version: "0.1.0",
    instructions: "Artifact management domain — create, version, and retrieve typed content objects."

  tool Therobotplans.Domains.Artifacts.Tools.Overview, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactCreate, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactGet, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactList, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactAddRevision, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactListRevisions, category: "Artifacts"
  tool Therobotplans.Domains.Artifacts.Tools.ArtifactGetBinary, category: "Artifacts"

  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
