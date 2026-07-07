defmodule TheRobotRemembersWeb.Plugs.MCPAuth do
  @moduledoc """
  Optional Guardian gate for the `/mcp` mount.

  No-op unless `MCP_AUTH_REQUIRED=true` (config `:the_robot_remembers, :mcp_auth, required:`),
  preserving Phase-0 dev-open behavior. When required, verifies the `Authorization: Bearer <jwt>`
  token via `TheRobotRemembers.Guardian` and stashes the claims under `conn.assigns[:mcp_auth_claims]`
  — the transport propagates that into the session as `:auth_claims`, where tools read it via
  `TheRobotRemembers.MCP.Auth.resolve_agent/2` to validate the self-asserted `agent` param.
  """
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if required?() do
      case bearer(conn) do
        nil ->
          unauthorized(conn)

        token ->
          case TheRobotRemembers.Guardian.decode_and_verify(token) do
            {:ok, claims} -> assign(conn, :mcp_auth_claims, claims)
            {:error, _reason} -> unauthorized(conn)
          end
      end
    else
      conn
    end
  end

  @doc "Whether MCP requests must present a valid Guardian JWT."
  def required?, do: Application.get_env(:the_robot_remembers, :mcp_auth, [])[:required] == true

  defp bearer(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> token
      ["bearer " <> token | _] -> token
      _ -> nil
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("www-authenticate", "Bearer")
    |> send_resp(401, Jason.encode!(%{error: "Authentication required"}))
    |> halt()
  end
end
