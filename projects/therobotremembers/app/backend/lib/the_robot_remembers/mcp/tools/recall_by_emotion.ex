defmodule TheRobotRemembers.MCP.Tools.RecallByEmotion do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "recall_by_emotion",
    description:
      "Recall memories by emotional resonance. Provide a target mood (valence/arousal/dominance); " <>
      "the harness adds the current hormone state and finds memories formed under a similar " <>
      "emotional signature — even when their content is unrelated. Returns a compact XML block.",
    category: "Memory"

  alias TheRobotRemembers.Memory

  input do
    field :valence, :number, description: "Target valence -1.0 .. 1.0"
    field :arousal, :number, description: "Target arousal 0.0 .. 1.0"
    field :dominance, :number, description: "Target dominance 0.0 .. 1.0"
    field :limit, :integer, description: "Max memories to return (default 12)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, _ctx) do
    owner = args[:agent] || "local"
    context = %{owner_agent: owner, requester_id: owner}
    opts = if l = args[:limit], do: [limit: l], else: []

    mood = Map.take(args, [:valence, :arousal, :dominance])
    emotional_state = %{mood: mood}

    case Memory.recall_by_emotion(emotional_state, opts, context) do
      {:ok, %{results: results, xml: xml}} ->
        {:ok, %{mode: "by_emotion", count: length(results), memories: xml}}

      {:error, reason} ->
        {:error, "recall_by_emotion failed: #{inspect(reason)}"}
    end
  end
end
