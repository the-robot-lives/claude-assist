defmodule TheRobotRemembers.MCP.Tools.CompartmentsList do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "compartments_list",
    description: "List the agent's memory access compartments (slug, classification, settings).",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      compartments = Console.compartments(agent)
      {:ok, %{agent: agent, count: length(compartments), compartments: compartments}}
    end
  end
end
