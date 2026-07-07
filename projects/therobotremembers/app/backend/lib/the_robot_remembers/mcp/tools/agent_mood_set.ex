defmodule TheRobotRemembers.MCP.Tools.AgentMoodSet do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "agent_mood_set",
    description:
      "Write the agent's current emotional state into memory_agent_state (the harness anchor for " <>
      "recall_by_emotion). Supply any of valence/arousal/dominance and the four hormones.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  @vad ~w(valence arousal dominance)a
  @hormones ~w(cortisol dopamine oxytocin serotonin)a

  input do
    field :valence, :number, description: "Mood valence -1.0 .. 1.0"
    field :arousal, :number, description: "Mood arousal 0.0 .. 1.0"
    field :dominance, :number, description: "Mood dominance 0.0 .. 1.0"
    field :cortisol, :number, description: "Cortisol 0.0 .. 1.0"
    field :dopamine, :number, description: "Dopamine 0.0 .. 1.0"
    field :oxytocin, :number, description: "Oxytocin 0.0 .. 1.0"
    field :serotonin, :number, description: "Serotonin 0.0 .. 1.0"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      {:ok, result} = Console.mood_set(agent, %{mood: Map.take(args, @vad), hormones: Map.take(args, @hormones)})
      {:ok, result}
    end
  end
end
