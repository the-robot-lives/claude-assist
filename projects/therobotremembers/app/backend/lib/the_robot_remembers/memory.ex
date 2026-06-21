defmodule TheRobotRemembers.Memory do
  @moduledoc """
  Public API for the associative memory engine — the surface the MCP tools and REST call.

  - `remember/2` — capture a memory (four texts + agent VAD; hormones stamped by the Monitor).
  - `recall/3` — active multi-path recall by a text query (semantic + emotional, RRF-fused).
  - `recall_by_emotion/3` — emotional-resonance recall by a target emotional state (pgvector).

  `context` is a map carrying at least `:owner_agent` (the tenant/identity) and optionally
  `:requester_id` / `:source_agent`.
  """
  alias TheRobotRemembers.Memory.{Store, Recall, Reinforcement}

  defdelegate remember(attrs, context \\ %{}), to: Store

  def recall(query, opts \\ [], context \\ %{}), do: Recall.active(query, opts, context)

  def recall_by_emotion(emotional_state, opts \\ [], context \\ %{}),
    do: Recall.by_emotion(emotional_state, opts, context)

  defdelegate reinforce(memory_id, context \\ %{}), to: Reinforcement
  defdelegate denforce(memory_id, context \\ %{}), to: Reinforcement
  defdelegate associations(memory_id, context \\ %{}), to: Reinforcement

  defdelegate archive(memory_id, context \\ %{}), to: Store
  defdelegate restore(memory_id, context \\ %{}), to: Store
end
