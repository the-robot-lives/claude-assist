defmodule TheRobotRemembers.MCP.Tools.Recall do
  @moduledoc false
  use Noizu.MCP.Server.Tool,
    name: "recall",
    description:
      "Active recall by a text query. Searches the four text facets (content/context/reflection/" <>
      "tangent) and the emotional path, fuses them, and returns the most relevant memories as a " <>
      "compact XML block for context injection.",
    category: "Memory"

  alias TheRobotRemembers.Memory

  input do
    field :query, :string, required: true, description: "What to recall (natural language)"
    field :limit, :integer, description: "Max memories to return (default 12)"
    field :agent, :string, description: "Owning agent identity (default \"local\")"
  end

  @impl true
  def call(args, _ctx) do
    owner = args[:agent] || "local"
    context = %{owner_agent: owner, requester_id: owner}
    opts = if l = args[:limit], do: [limit: l], else: []

    case Memory.recall(args[:query], opts, context) do
      {:ok, %{results: results, xml: xml}} ->
        {:ok, %{mode: "active", count: length(results), memories: xml}}

      {:error, reason} ->
        {:error, "recall failed: #{inspect(reason)}"}
    end
  end
end
