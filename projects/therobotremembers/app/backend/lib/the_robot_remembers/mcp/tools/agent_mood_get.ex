defmodule TheRobotRemembers.MCP.Tools.AgentMoodGet do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "agent_mood_get",
    description:
      "Read the agent's current emotional state (VAD mood + hormones) from memory_agent_state, " <>
      "falling back to the Monitor-stub baseline when none is stored.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  input do
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      {:ok, Console.mood_get(agent)}
    end
  end
end
