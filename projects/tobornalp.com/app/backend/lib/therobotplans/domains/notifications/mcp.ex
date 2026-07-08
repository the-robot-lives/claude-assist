defmodule Therobotplans.Domains.Notifications.MCP do
  use Noizu.MCP.Server,
    name: "tobornalp_notifications",
    version: "0.1.0",
    instructions:
      "Notifications domain — a per-recipient inbox. Notify sends a short DM (<=128 chars) to a user or list of users. Run a Monitor on Notifications.Poll to be woken the instant a notification arrives instead of polling on a timer; Notifications.Get is the immediate cursor pull. Mark items seen/read/ack and clear. Notifications are also generated automatically by item assignment, comments, and mentions."

  tool Therobotplans.Domains.Notifications.Tools.Overview, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Notify, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Get, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Poll, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.MarkRead, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.MarkSeen, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Ack, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Clear, category: "Notifications"
  tool Therobotplans.Domains.Notifications.Tools.Watch, category: "Notifications"

  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
