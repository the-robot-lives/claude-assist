defmodule Therobotplans.Domains.Wiki.Tools.AttachmentList do
  use Noizu.MCP.Server.Tool,
    name: "Wiki.AttachmentList",
    description: "List attachments on a wiki page.",
    hidden: true,
    category: "Wiki",
    annotations: [read_only_hint: true]

  input do
    field :page, :string, required: true, description: "Page UUID"
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
        attachments = Wiki.list_attachments(page.id)

        {:ok, %{
          attachments: Enum.map(attachments, fn a ->
            %{id: a.id, artifact_type: a.artifact_type, url: a.url, description: a.description, created_by: a.created_by, created_at: a.inserted_at}
          end),
          count: length(attachments)
        }}
    end
  end
end
