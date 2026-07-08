defmodule Therobotplans.Domains.Items.Tools.DefinitionDelete do
  use Noizu.MCP.Server.Tool,
    name: "Item.Definition.Delete",
    description: "Soft-delete an item type definition.",
    hidden: true,
    category: "Items.Types"

  input do
    field :organization, :string,
      description: "Organization slug or UUID. Omit to target a global type."

    field :project, :string,
      description: "Project slug or UUID — targets the project-scoped type."

    field :slug, :string,
      required: true,
      description: "Type slug to delete (within the chosen scope)"
  end

  alias Therobotplans.Domains.Items.Definitions
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, _ctx) do
    slug = Args.get(args, :slug)

    with {:ok, org_id, project_id} <-
           Resolve.scope(Args.get(args, :organization), Args.get(args, :project)),
         %{id: id} <- Definitions.get_type_in_scope(org_id, project_id, slug) do
      Definitions.delete_type(id)
      {:ok, %{deleted: slug}}
    else
      nil -> {:error, "Type '#{slug}' not found in the given scope"}
      {:error, _} -> {:error, "Scope could not be resolved"}
    end
  end
end
