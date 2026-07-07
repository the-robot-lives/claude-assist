defmodule TheRobotRemembers.MCP.Tools.MemoryArchive do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "memory_archive",
    description: "Archive a memory: it drops out of recall but stays restorable. Tenant-checked.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :memory_id, :string, required: true, description: "The memory id to archive"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      case Console.archive(agent, args[:memory_id]) do
        {:ok, memory} -> {:ok, %{memory: memory, status: "archived"}}
        {:error, :not_found} -> {:error, "memory not found"}
        {:error, :forbidden} -> {:error, "memory not owned by #{agent}"}
        {:error, reason} -> {:error, "archive failed: #{inspect(reason)}"}
      end
    end
  end
end
