defmodule TheRobotRemembers.MCP.Tools.GraphSubgraph do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "graph_subgraph",
    description:
      "Return an agent's association subgraph (nodes + edges). Without `seed`, the whole graph of " <>
      "edges at/above `min_weight` (node-capped by `limit`); with `seed`, the traversal " <>
      "neighborhood of that memory up to `hops`. Edges only appear when both endpoints belong to " <>
      "the agent.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :agent, :string, description: "Owning agent identity (default \"local\")"
    field :seed, :string, description: "Optional seed memory id — return its neighborhood"
    field :compartment, :string, description: "Optional compartment filter"
    field :min_weight, :number, description: "Minimum edge weight (default 0.2)"
    field :hops, :integer, description: "Traversal depth with a seed (default 2, max 3)"
    field :limit, :integer, description: "Node cap (default 500)"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      {:ok,
       Console.subgraph(agent,
         seed: args[:seed],
         compartment: args[:compartment],
         min_weight: args[:min_weight],
         hops: args[:hops],
         limit: args[:limit]
       )}
    end
  end
end
