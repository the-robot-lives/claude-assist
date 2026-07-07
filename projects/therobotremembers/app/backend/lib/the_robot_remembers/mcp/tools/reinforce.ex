defmodule TheRobotRemembers.MCP.Tools.Reinforce do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "reinforce",
    description: "Strengthen a memory you found useful (raises its decay weight, slowing forgetting).",
    category: "Memory"

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.MCP.Auth

  input do
    field :memory_id, :string, required: true, description: "The memory id to reinforce"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, owner} <- Auth.resolve_agent(ctx, args[:agent]) do
      case Memory.reinforce(args[:memory_id], %{owner_agent: owner}) do
        {:ok, weight} -> {:ok, %{memory_id: args[:memory_id], decay_weight: weight, status: "reinforced"}}
        {:error, :not_found} -> {:error, "memory not found"}
        {:error, reason} -> {:error, "reinforce failed: #{inspect(reason)}"}
      end
    end
  end
end
