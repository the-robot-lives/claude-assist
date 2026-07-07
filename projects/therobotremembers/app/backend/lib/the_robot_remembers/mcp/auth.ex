defmodule TheRobotRemembers.MCP.Auth do
  @moduledoc """
  Bridges the optional MCP auth gate (`MCP_AUTH_REQUIRED`) into the tools.

  When the `/mcp` mount is gated (see `TheRobotRemembersWeb.Plugs.MCPAuth`), the verified Guardian
  claims flow through the transport into `ctx.assigns[:auth_claims]`. `resolve_agent/2` then binds
  the effective agent to the authenticated identity:

    * mount dev-open (no claims) — trust the self-asserted `agent` (default `"local"`).
    * claims present with an explicit `agent` claim — that claim wins; a self-asserted `agent` that
      disagrees is rejected.
    * claims present without an `agent` claim (a standard user JWT — its subject is a user-session
      ref, not an agent identity) — the caller is authenticated, but with no user→agent binding in
      the schema we trust the self-asserted `agent`. Tightening this needs a user↔agent mapping
      (a Phase-2 follow-up).
  """
  @default_agent "local"

  @spec resolve_agent(term(), String.t() | nil) :: {:ok, String.t()} | {:error, String.t()}
  def resolve_agent(ctx, requested) do
    case claims(ctx) do
      nil ->
        {:ok, requested || @default_agent}

      claims ->
        case explicit_agent(claims) do
          nil ->
            {:ok, requested || @default_agent}

          agent ->
            cond do
              requested in [nil, ""] -> {:ok, agent}
              requested == agent -> {:ok, agent}
              true -> {:error, "authenticated identity '#{agent}' may not act as agent '#{requested}'"}
            end
        end
    end
  end

  defp claims(%{assigns: assigns}) when is_map(assigns), do: assigns[:auth_claims]
  defp claims(_), do: nil

  defp explicit_agent(claims) when is_map(claims), do: claims["agent"] || claims[:agent]
  defp explicit_agent(_), do: nil
end
