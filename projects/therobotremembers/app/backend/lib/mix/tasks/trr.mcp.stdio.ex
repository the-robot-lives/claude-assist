defmodule Mix.Tasks.Trr.Mcp.Stdio do
  @shortdoc "Run the tobor_memory MCP server over stdio (for `claude mcp add`)."
  @moduledoc """
  Starts the application and the `TheRobotRemembers.MCP` server bound to stdio, so a local
  agent can connect via a command transport:

      claude mcp add tobor-memory -- mix trr.mcp.stdio

  Requires the database (and, for semantic recall, OPENAI_API_KEY + WEAVIATE_URL) to be
  reachable. Emotional-resonance recall works with just the database.
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    # Keep stdout clean for JSON-RPC framing; logs go to stderr.
    Logger.configure(level: :warning)

    children = [{TheRobotRemembers.MCP, transport: :stdio}]
    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
    Process.sleep(:infinity)
  end
end
