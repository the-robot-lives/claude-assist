defmodule Therobotplans.Domains.Wiki.Tools.AttachmentCreate do
  use Noizu.MCP.Server.Tool,
    name: "Wiki.AttachmentCreate",
    description: "Attach an artifact, URL, or file reference to a wiki page.",
    hidden: true,
    category: "Wiki"

  input do
    field :page, :string, required: true, description: "Page UUID"
    field :artifact_type, :string, required: true, description: "artifact, url, git_branch, or file"
    field :url, :string, description: "URL or media reference"
    field :git_branch, :string, description: "Branch name (for git_branch type)"
    field :description, :string, description: "Attachment description / file name"
    field :created_by, :string, description: "Author persona slug"
  end

  alias Therobotplans.Domains.Wiki
  alias Therobotplans.MCP.Args

  @impl true
  def call(args, _ctx) do
    page_id = Args.get(args, :page)

    case Wiki.get_page(page_id) do
      nil ->
        {:error, "Page '#{page_id}' not found"}

      page ->
        attrs = %{
          page_id: page.id,
          artifact_type: Args.get(args, :artifact_type),
          url: Args.get(args, :url),
          git_branch: Args.get(args, :git_branch),
          description: Args.get(args, :description),
          created_by: Args.get(args, :created_by)
        }

        case Wiki.create_attachment(attrs) do
          {:ok, attachment} ->
            {:ok, %{id: attachment.id, artifact_type: attachment.artifact_type, url: attachment.url, description: attachment.description}}

          {:error, changeset} ->
            {:error, "Failed: #{inspect(changeset.errors)}"}
        end
    end
  end
end
