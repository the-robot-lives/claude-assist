defmodule Therobotplans.Domains.Goals.MCP do
  use Noizu.MCP.Server,
    name: "tobornalp_goals",
    version: "0.1.0",
    instructions:
      "Goals domain — OKRs (objectives + key results + check-ins). Objectives cascade company→team→individual→personal; progress rolls up from key results. An item-backed KR auto-computes its current_value from the completion of its linked items."

  tool Therobotplans.Domains.Goals.Tools.Overview, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.ObjectiveCreate, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.ObjectiveGet, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.ObjectiveUpdate, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.ObjectiveList, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.KeyResultCreate, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.KeyResultUpdate, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.KeyResultLinkItem, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.KeyResultProgress, category: "Goals"
  tool Therobotplans.Domains.Goals.Tools.CheckinCreate, category: "Goals"

  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
