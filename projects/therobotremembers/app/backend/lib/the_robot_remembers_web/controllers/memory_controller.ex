defmodule TheRobotRemembersWeb.MemoryController do
  @moduledoc """
  Memory console HTTP surface (API contract Phase D). Reads/preview run under `:authenticated`
  (viewer); mutations additionally require the global admin flag (see the router — "editor+" is
  realized as `:admin` because memory agents are not org-scoped and `RequireRole` is
  org-membership-based). Every action delegates to `TheRobotRemembers.Memory.Console`, the same
  internal API the MCP tools call, so HTTP and MCP stay behaviourally identical.
  """
  use TheRobotRemembersWeb, :controller

  alias TheRobotRemembers.Guardian
  alias TheRobotRemembers.Memory.Console

  def agents(conn, _params) do
    json(conn, %{agents: Console.agents()})
  end

  def graph(conn, %{"agent_id" => agent_id} = params) do
    opts = [
      compartment: params["compartment"],
      min_weight: params["min_weight"],
      hops: params["hops"],
      seed: params["seed"],
      limit: params["limit"]
    ]

    json(conn, Console.subgraph(agent_id, opts))
  end

  def recall_preview(conn, %{"agent_id" => agent_id} = params) do
    query = params["query"]
    mood = params["mood"]

    if blank?(query) and (is_nil(mood) or mood == %{}) do
      error(conn, 400, "at least one of query or mood is required")
    else
      {:ok, result} = Console.recall_preview(agent_id, params)
      json(conn, result)
    end
  end

  def update_edge(conn, %{"agent_id" => agent_id, "edge_id" => edge_id} = params) do
    case params["weight"] do
      nil ->
        error(conn, 400, "weight is required")

      weight ->
        meta = %{reason: params["reason"], created_by: "user:#{current_user_id(conn)}"}
        # Single-entity mutations are wrapped ({ edge } / { memory }) per the API convention.
        respond(conn, :edge, Console.set_edge_weight(agent_id, edge_id, weight, meta))
    end
  end

  def update_memory(conn, %{"agent_id" => agent_id, "memory_id" => memory_id} = params) do
    attrs = Map.take(params, ["decay_weight", "pinned"])
    respond(conn, :memory, Console.set_memory(agent_id, memory_id, attrs))
  end

  def reinforce(conn, %{"agent_id" => agent_id, "memory_id" => memory_id}) do
    respond(conn, :memory, Console.reinforce(agent_id, memory_id))
  end

  def denforce(conn, %{"agent_id" => agent_id, "memory_id" => memory_id}) do
    respond(conn, :memory, Console.denforce(agent_id, memory_id))
  end

  # ── helpers ─────────────────────────────────────────────────────
  defp respond(conn, key, {:ok, view}), do: json(conn, %{key => view})
  defp respond(conn, _key, {:error, :not_found}), do: error(conn, 404, "not found")
  defp respond(conn, _key, {:error, :forbidden}), do: error(conn, 403, "not owned by this agent")
  defp respond(conn, _key, {:error, :no_changes}), do: error(conn, 422, "no recognized fields to update")
  defp respond(conn, _key, {:error, reason}), do: error(conn, 422, inspect(reason))

  defp error(conn, status, message) do
    conn |> put_status(status) |> json(%{error: message})
  end

  defp blank?(nil), do: true
  defp blank?(s) when is_binary(s), do: String.trim(s) == ""
  defp blank?(_), do: false

  defp current_user_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      %TheRobotRemembers.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %TheRobotRemembers.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> "unknown"
    end
  end
end
