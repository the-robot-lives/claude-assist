defmodule Therobotplans.Domains.Items.Tools.ItemAttach do
  use Noizu.MCP.Server.Tool,
    name: "Item.Attach",
    description: "Attach an artifact, URL, or git branch to an item.",
    hidden: true,
    category: "Items"

  input do
    field :item_id, :string, required: true, description: "Item UUID"
    field :artifact_type, :string, required: true, description: "artifact, url, git_branch, or file"
    field :url, :string, description: "URL (for url/file types)"
    field :git_branch, :string, description: "Branch name (for git_branch type)"
    field :description, :string, description: "Attachment description"
    field :created_by, :string, description: "Persona slug"
  end

  alias Therobotplans.Services.Attach

  @impl true
  def call(args, _ctx) do
    item_id = args[:item_id] || args["item_id"]

    attrs = %{
      artifact_type: args[:artifact_type] || args["artifact_type"],
      url: args[:url] || args["url"],
      git_branch: args[:git_branch] || args["git_branch"],
      description: args[:description] || args["description"],
      created_by: args[:created_by] || args["created_by"]
    }

    case Attach.add("item", item_id, attrs) do
      {:ok, att} ->
        {:ok, %{id: att.id, item_id: item_id, artifact_type: att.artifact_type}}
      {:error, changeset} ->
        {:error, "Failed: #{inspect(changeset.errors)}"}
    end
  end
end
