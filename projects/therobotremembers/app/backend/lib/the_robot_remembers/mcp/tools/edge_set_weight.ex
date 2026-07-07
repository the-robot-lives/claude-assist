defmodule TheRobotRemembers.MCP.Tools.EdgeSetWeight do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "edge_set_weight",
    description:
      "Set an association edge's weight (clamped 0..1) with provenance. The change flows to the " <>
      "AGE graph projection (including removal when it drops below the mirror threshold). Both " <>
      "endpoints must belong to the agent.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :edge_id, :string, required: true, description: "The association edge id"
    field :weight, :number, required: true, description: "New weight, clamped to [0.0, 1.0]"
    field :reason, :string, description: "Why the weight was changed (audited)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      meta = %{reason: args[:reason], created_by: "mcp:#{agent}"}

      case Console.set_edge_weight(agent, args[:edge_id], args[:weight], meta) do
        {:ok, edge} -> {:ok, %{edge: edge, status: "updated"}}
        {:error, :not_found} -> {:error, "edge not found"}
        {:error, :forbidden} -> {:error, "edge not owned by #{agent}"}
        {:error, reason} -> {:error, "edge_set_weight failed: #{inspect(reason)}"}
      end
    end
  end
end
