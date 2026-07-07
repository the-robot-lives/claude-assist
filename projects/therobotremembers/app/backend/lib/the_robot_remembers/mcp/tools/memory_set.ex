defmodule TheRobotRemembers.MCP.Tools.MemorySet do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "memory_set",
    description:
      "Update a memory's decay_weight (clamped 0.05..1.0) and/or pinned flag. Tenant-checked to " <>
      "the owning agent.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :memory_id, :string, required: true, description: "The memory id to update"
    field :decay_weight, :number, description: "New decay weight, clamped to [0.05, 1.0]"
    field :pinned, :boolean, description: "Pin (protect from decay) or unpin"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      attrs =
        %{}
        |> put_present(args, :decay_weight)
        |> put_present(args, :pinned)

      case Console.set_memory(agent, args[:memory_id], attrs) do
        {:ok, memory} -> {:ok, %{memory: memory, status: "updated"}}
        {:error, :not_found} -> {:error, "memory not found"}
        {:error, :forbidden} -> {:error, "memory not owned by #{agent}"}
        {:error, :no_changes} -> {:error, "supply decay_weight and/or pinned"}
        {:error, reason} -> {:error, "memory_set failed: #{inspect(reason)}"}
      end
    end
  end

  defp put_present(attrs, args, key) do
    if Map.has_key?(args, key), do: Map.put(attrs, key, args[key]), else: attrs
  end
end
