defmodule TheRobotRemembers.Agents.Sentinel do
  @moduledoc """
  The Sentinel enforces access control on recall. PHASE 0: ownership + classification gate
  (an agent reads its own memories; `sealed` is never returned across owners). The ACL
  predicate is applied *in-query* by the recall paths; this module is the policy authority
  and the final-filter backstop. Compartment bridging / redaction arrive later.
  """

  @doc "SQL-safe owner filter for recall queries (Phase 0: an agent sees its own memories)."
  def owner_scope(%{owner_agent: owner}) when is_binary(owner), do: owner
  def owner_scope(_), do: nil

  @doc "Backstop filter applied to hydrated rows after fusion."
  def authorize(memories, context) when is_list(memories) do
    owner = owner_scope(context)
    Enum.filter(memories, &allowed?(&1, owner))
  end

  defp allowed?(mem, owner) do
    mem_owner = Map.get(mem, :owner_agent) || Map.get(mem, "owner_agent")
    classification = Map.get(mem, :classification) || Map.get(mem, "classification")
    cond do
      owner == nil -> classification in [:open, "open"]
      mem_owner == owner -> true
      true -> false
    end
  end
end
