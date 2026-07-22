defmodule Therobotplans.Domains.Wiki.Tools.PageDelete do
  use Noizu.MCP.Server.Tool,
    name: "Wiki.PageDelete",
    description: "Delete a wiki page (cascades to its comments, attachments, and reactions).",
    hidden: true,
    category: "Wiki"

  input do
    field :page, :string, required: true, description: "Page UUID"
  end

  alias Therobotplans.Domains.Wiki
  alias Therobotplans.MCP.Args

  @impl true
  def call(args, _ctx) do
    id = Args.get(args, :page)

    case Wiki.delete_page(id) do
      {:ok, _} -> {:ok, %{deleted: true, id: id}}
      {:error, :not_found} -> {:error, "Page '#{id}' not found"}
      {:error, changeset} -> {:error, "Failed: #{inspect(changeset.errors)}"}
    end
  end
end
