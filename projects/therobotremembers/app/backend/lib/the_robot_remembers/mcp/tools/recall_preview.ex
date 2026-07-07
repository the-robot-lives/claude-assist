defmodule TheRobotRemembers.MCP.Tools.RecallPreview do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "recall_preview",
    description:
      "Side-effect-free recall (no reinforcement): returns the ranked memories plus, per result, " <>
      "the RRF contribution breakdown (which paths surfaced it and how strongly). Supply a `query` " <>
      "and/or a target mood (valence/arousal/dominance + hormones); at least one is required.",
    category: "Memory"

  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.MCP.Auth

  @mood_fields ~w(valence arousal dominance cortisol dopamine oxytocin serotonin)a

  input do
    field :query, :string, description: "Text to recall (natural language)"
    field :valence, :number, description: "Target mood valence -1.0 .. 1.0"
    field :arousal, :number, description: "Target mood arousal 0.0 .. 1.0"
    field :dominance, :number, description: "Target mood dominance 0.0 .. 1.0"
    field :cortisol, :number, description: "Target cortisol 0.0 .. 1.0"
    field :dopamine, :number, description: "Target dopamine 0.0 .. 1.0"
    field :oxytocin, :number, description: "Target oxytocin 0.0 .. 1.0"
    field :serotonin, :number, description: "Target serotonin 0.0 .. 1.0"
    field :limit, :integer, description: "Max results (default 12)"
    field :rrf_k, :integer, description: "RRF k override (default 60)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, ctx) do
    with {:ok, agent} <- Auth.resolve_agent(ctx, args[:agent]) do
      mood = Map.take(args, @mood_fields)
      overrides = if k = args[:rrf_k], do: %{rrf_k: k}, else: nil

      cond do
        blank?(args[:query]) and mood == %{} ->
          {:error, "supply a query and/or a target mood"}

        true ->
          params = %{
            query: args[:query],
            mood: (if mood == %{}, do: nil, else: mood),
            limit: args[:limit],
            overrides: overrides
          }

          Console.recall_preview(agent, params)
      end
    end
  end

  defp blank?(nil), do: true
  defp blank?(s) when is_binary(s), do: String.trim(s) == ""
  defp blank?(_), do: false
end
