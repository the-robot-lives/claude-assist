defmodule TheRobotRemembers.MCP.Tools.MemoryRestore do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "memory_restore",
    description: "Restore an archived memory to active so it can be recalled again. Tenant-checked.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :memory_id, :string, required: true, description: "The memory id to restore"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      case Console.restore(agent, args[:memory_id]) do
        {:ok, memory} -> {:ok, %{memory: memory, status: "restored"}}
        {:error, :not_found} -> {:error, "memory not found"}
        {:error, :forbidden} -> {:error, "memory not owned by #{agent}"}
        {:error, reason} -> {:error, "restore failed: #{inspect(reason)}"}
      end
    end
  end
end
