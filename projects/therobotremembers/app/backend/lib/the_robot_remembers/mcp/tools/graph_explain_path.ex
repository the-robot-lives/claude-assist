defmodule TheRobotRemembers.MCP.Tools.GraphExplainPath do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "graph_explain_path",
    description:
      "Explain how two of an agent's memories are connected: the ranked graph paths between them " <>
      "(node sequence, the edges walked with type + weight, and the path score) via the active " <>
      "GraphStore adapter (CTE or AGE).",
    category: "Graph"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :from_id, :string, required: true, description: "Source memory id"
    field :to_id, :string, required: true, description: "Target memory id"
    field :max_hops, :integer, description: "Max path length (default 3)"
    field :min_weight, :number, description: "Minimum edge weight (default 0.2)"
    field :limit, :integer, description: "Max paths to return (default 50)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      opts =
        [max_hops: args[:max_hops], min_weight: args[:min_weight], limit: args[:limit]]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      case Console.explain_paths(agent, args[:from_id], [args[:to_id]], opts) do
        {:ok, result} -> {:ok, result}
        {:error, :not_found} -> {:error, "memory not found"}
        {:error, :forbidden} -> {:error, "memory not owned by #{agent}"}
        {:error, reason} -> {:error, "explain_paths failed: #{inspect(reason)}"}
      end
    end
  end
end
