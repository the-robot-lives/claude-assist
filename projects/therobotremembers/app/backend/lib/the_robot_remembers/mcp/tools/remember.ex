defmodule TheRobotRemembers.MCP.Tools.Remember do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "remember",
    description:
      "Capture a memory. `content` is required. Optionally describe `context` (what you were " <>
      "doing), `reflection` (your thoughts/feelings/mood in words), and `tangent` (what else it " <>
      "makes you think of) — each is embedded for future search; the tangent also seeds an " <>
      "association. Supply `valence`/`arousal`/`dominance` for mood; hormones are tracked by the " <>
      "harness, not you. Returns the memory id and status.",
    category: "Memory"

  alias TheRobotRemembers.Memory
  alias TheRobotRemembers.MCP.Auth

  input do
    field :content, :string, required: true, description: "The memory / event itself (required)"
    field :context, :string, description: "What you were doing when this happened (situational)"
    field :reflection, :string, description: "Your thoughts / feelings / mood, in words"
    field :tangent, :string, description: "What else this memory makes you think of"
    field :summary, :string, description: "Optional short summary for injection"
    field :content_type, :string, description: "episodic | semantic | procedural (default episodic)"
    field :valence, :number, description: "Mood valence -1.0 (negative) .. 1.0 (positive)"
    field :arousal, :number, description: "Mood arousal 0.0 (calm) .. 1.0 (excited)"
    field :dominance, :number, description: "Mood dominance 0.0 (helpless) .. 1.0 (in control)"
    field :domain, :string, description: "e.g. debugging, design, ops"
    field :topic, :string, description: "Conversation topic"
    field :collaborators, :string, description: "Comma-separated collaborator ids/names"
    field :compartment, :string, description: "Access compartment (default \"default\")"
    field :classification, :string, description: "open | restricted | sealed (default open)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, owner} <- Auth.resolve_agent(ctx, args[:agent]) do
      do_call(args, owner)
    end
  end

  defp do_call(args, owner) do
    context = %{owner_agent: owner, requester_id: owner, source_agent: "mcp"}

    attrs = %{
      content: args[:content],
      context: args[:context],
      reflection: args[:reflection],
      tangent: args[:tangent],
      summary: args[:summary],
      content_type: args[:content_type] || "episodic",
      mood: mood(args),
      domain: args[:domain],
      topic: args[:topic],
      collaborators: split(args[:collaborators]),
      compartment: args[:compartment] || "default",
      classification: args[:classification] || "open"
    }

    case Memory.remember(attrs, context) do
      {:ok, %{id: id, status: status, confidence: conf}} ->
        {:ok, %{id: id, status: to_string(status), confidence: conf}}

      {:error, reason} ->
        {:error, "remember failed: #{inspect(reason)}"}
    end
  end

  defp mood(args) do
    vals = Map.take(args, [:valence, :arousal, :dominance])
    if vals == %{}, do: nil, else: vals
  end

  defp split(nil), do: []
  defp split(""), do: []
  defp split(s) when is_binary(s), do: s |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
end
