defmodule Therobotplans.Domains.Items.Tools.QueueFeed do
  use Noizu.MCP.Server.Tool,
    name: "Item.Queue.Feed",
    description: "Activity feed for an item queue.",
    hidden: true,
    category: "Items.Queues",
    annotations: [read_only_hint: true]

  input do
    field :slug, :string, required: true, description: "Queue slug"
    field :limit, :integer, description: "Max events (default 50)"
  end

  @impl true
  def call(args, _ctx) do
    slug = args[:slug] || args["slug"]

    {:ok,
     %{
       queue: slug,
       events: [],
       hint: "Activity feed not yet implemented."
     }}
  end
end
