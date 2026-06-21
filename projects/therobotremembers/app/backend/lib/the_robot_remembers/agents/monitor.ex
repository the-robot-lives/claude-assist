defmodule TheRobotRemembers.Agents.Monitor do
  @moduledoc """
  The Monitor owns the agent's emotional/hormonal harness state.

  PHASE 0 STUB: returns static config baselines. From Phase 2 this becomes a per-agent
  GenServer (`noizu_labs_services` pool) whose hormone levels rise on interaction events
  (cortisol↑ on contradiction/quarantine, dopamine↑ on reinforcement, etc.) and relax toward
  the disposition baseline — the value stamped onto each memory at formation.
  """
  alias TheRobotRemembers.Memory.Emotion

  @doc "Current hormone snapshot for an agent (stamped onto memories at formation)."
  def current_hormones(_owner_agent), do: Emotion.hormone_baseline()

  @doc "Current full emotional state (mood + hormones) — used as the default recall_by_emotion anchor."
  def current_emotional(owner_agent) do
    %{mood: Emotion.neutral_mood(), hormones: current_hormones(owner_agent)}
  end

  @doc "Phase 2+: nudge hormone state from an interaction event. No-op in the stub."
  def observe(_owner_agent, _event), do: :ok
end
