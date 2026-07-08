defmodule Therobotplans.Domains.Items.Tools.ItemList do
  use Noizu.MCP.Server.Tool,
    name: "Item.List",
    description: "List items with optional filters.",
    hidden: true,
    category: "Items",
    annotations: [read_only_hint: true]

  input do
    field :organization, :string,
      required: true,
      description: "Organization slug or UUID (required)"

    field :status, :string, description: "Filter by status"
    field :item_type, :string, description: "Filter by type slug"
    field :priority, :string, description: "Filter by priority"
    field :assignee, :string, description: "Filter by assignee"
    field :project, :string, description: "Filter by project slug or UUID"
    field :queue_id, :string, description: "Filter by queue UUID"
    field :parent_id, :string, description: "Filter by parent item UUID"
    field :limit, :integer, description: "Max results (default 50)"
    field :offset, :integer, description: "Pagination offset"
  end

  alias Therobotplans.Domains.Items
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, _ctx) do
    org_ref = Args.get(args, :organization)

    case Resolve.organization_id(org_ref) do
      nil ->
        {:error, "Organization '#{org_ref}' not found"}

      org_id ->
        project = Resolve.project(Args.get(args, :project))

        opts =
          [:status, :item_type, :priority, :assignee, :queue_id, :parent_id, :limit, :offset]
          |> Enum.reduce([organization_id: org_id], fn key, acc ->
            val = args[key] || args[Atom.to_string(key)]
            if val, do: [{key, val} | acc], else: acc
          end)
          |> then(fn opts -> if project, do: [{:project_id, project.id} | opts], else: opts end)

        items = Items.list(opts)

        {:ok,
         %{
           items:
             Enum.map(items, fn t ->
               %{
                 id: t.id,
                 title: t.title,
                 item_type: t.item_type,
                 status: t.status,
                 priority: t.priority,
                 assignee: t.assignee,
                 created_at: t.inserted_at
               }
             end),
           count: length(items)
         }}
    end
  end
end
