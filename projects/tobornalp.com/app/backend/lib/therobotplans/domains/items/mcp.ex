defmodule Therobotplans.Domains.Items.MCP do
  use Noizu.MCP.Server,
    name: "tobornalp_items",
    version: "0.1.0",
    instructions: "Item management domain — create and track items (tasks/bugs/todos/epics), boards (queues), and custom field/type definitions."

  # Core CRUD
  tool Therobotplans.Domains.Items.Tools.Overview, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemCreate, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemFromEntity, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemGet, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemUpdate, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemList, category: "Items"

  # Cross-cutting
  tool Therobotplans.Domains.Items.Tools.ItemComment, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemWatch, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemAttach, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemFeed, category: "Items"

  # Links
  tool Therobotplans.Domains.Items.Tools.ItemLink, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemUnlink, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemLinkEntity, category: "Items"
  tool Therobotplans.Domains.Items.Tools.ItemUnlinkEntity, category: "Items"

  # Queues (boards)
  tool Therobotplans.Domains.Items.Tools.QueueCreate, category: "Items.Queues"
  tool Therobotplans.Domains.Items.Tools.QueueGet, category: "Items.Queues"
  tool Therobotplans.Domains.Items.Tools.QueueList, category: "Items.Queues"
  tool Therobotplans.Domains.Items.Tools.QueueFeed, category: "Items.Queues"

  # Type definitions
  tool Therobotplans.Domains.Items.Tools.DefinitionCreate, category: "Items.Types"
  tool Therobotplans.Domains.Items.Tools.DefinitionGet, category: "Items.Types"
  tool Therobotplans.Domains.Items.Tools.DefinitionUpdate, category: "Items.Types"
  tool Therobotplans.Domains.Items.Tools.DefinitionDelete, category: "Items.Types"

  # Field definitions
  tool Therobotplans.Domains.Items.Tools.FieldDefinitionCreate, category: "Items.Fields"
  tool Therobotplans.Domains.Items.Tools.FieldDefinitionUpdate, category: "Items.Fields"
  tool Therobotplans.Domains.Items.Tools.FieldDefinitionDelete, category: "Items.Fields"

  # Discovery
  tool Therobotplans.Tools.ToolSummary, category: "Discovery"
  tool Therobotplans.Tools.ToolSearch, category: "Discovery"
  tool Therobotplans.Tools.ToolDefinition, category: "Discovery"
  tool Therobotplans.Tools.ToolCall, category: "Discovery"
  tool Therobotplans.Tools.ToolHelp, category: "Discovery"
end
