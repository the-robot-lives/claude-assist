defmodule TheRobotRemembers.MCP.Tools.Denforce do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "denforce",
    description: "Weaken a memory that was irrelevant or wrong (lowers its decay weight, hastening forgetting).",
    category: "Memory"

  alias TheRobotRemembers.Memory

  input do
    field :memory_id, :string, required: true, description: "The memory id to denforce"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, _ctx) do
    owner = args[:agent] || "local"

    case Memory.denforce(args[:memory_id], %{owner_agent: owner}) do
      {:ok, weight} -> {:ok, %{memory_id: args[:memory_id], decay_weight: weight, status: "denforced"}}
      {:error, :not_found} -> {:error, "memory not found"}
      {:error, reason} -> {:error, "denforce failed: #{inspect(reason)}"}
    end
  end
end
