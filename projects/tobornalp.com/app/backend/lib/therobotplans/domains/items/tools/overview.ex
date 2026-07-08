defmodule Therobotplans.Domains.Items.Tools.Overview do
  use Noizu.MCP.Server.Tool,
    name: "Item.Overview",
    description: "List item tools, available item types, and status counts.",
    annotations: [read_only_hint: true],
    category: "Items"

  input do
    field :organization, :string,
      description: "Organization slug or UUID — when given, lists that org's item types"
  end

  alias Therobotplans.Domains.Items
  alias Therobotplans.Domains.Items.Definitions
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, _ctx) do
    # Effective item types for the org context (global ∪ org, resolved).
    types =
      case Resolve.organization_id(Args.get(args, :organization)) do
        nil -> Definitions.effective_types(nil, nil)
        org_id -> Definitions.effective_types(org_id, nil)
      end

    status_counts = Items.count_by_status()

    {:ok,
     %{
       domain: "Items",
       subdomain: "items.tobor.locker",
       status_counts: status_counts,
       item_types:
         Enum.map(types, fn t ->
           %{slug: t.slug, name: t.name, description: t.description}
         end),
       tools: %{
         crud: ["Item.Create", "Item.Get", "Item.Update", "Item.List"],
         cross_cutting: ["Item.Comment", "Item.Watch", "Item.Attach", "Item.Feed"],
         links: ["Item.Link", "Item.Unlink"],
         queues: ["Item.Queue.Create", "Item.Queue.Get", "Item.Queue.List", "Item.Queue.Feed"],
         definitions: [
           "Item.Definition.Create",
           "Item.Definition.Get",
           "Item.Definition.Update",
           "Item.Definition.Delete"
         ],
         fields: [
           "Item.Field.Definition.Create",
           "Item.Field.Definition.Update",
           "Item.Field.Definition.Delete"
         ]
       }
     }}
  end
end
