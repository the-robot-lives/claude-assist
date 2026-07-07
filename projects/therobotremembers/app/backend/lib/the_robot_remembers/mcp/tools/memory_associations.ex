defmodule TheRobotRemembers.MCP.Tools.MemoryAssociations do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "memory_associations",
    description: "List a memory's association edges (type, weight, neighbor) — the local shape of the web.",
    category: "Memory"

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.MCP.Auth

  input do
    field :memory_id, :string, required: true, description: "The memory id to inspect"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, owner} <- Auth.resolve_agent(ctx, args[:agent]) do
      do_call(args, owner)
    end
  end

  defp do_call(args, owner) do
    edges = Memory.associations(args[:memory_id], %{owner_agent: owner})

    formatted =
      Enum.map(edges, fn e ->
        neighbor = if e.source_memory_id == args[:memory_id], do: e.target_memory_id, else: e.source_memory_id

        %{
          neighbor: neighbor,
          type: to_string(e.edge_type),
          weight: Float.round(e.weight * 1.0, 3),
          reason: e.reason
        }
      end)

    {:ok, %{memory_id: args[:memory_id], count: length(formatted), associations: formatted}}
  end
end
