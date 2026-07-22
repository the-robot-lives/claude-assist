defmodule Therobotplans.Domains.Wiki.Tools.CommentCreate do
  use Noizu.MCP.Server.Tool,
    name: "Wiki.CommentCreate",
    description: "Add a comment to a wiki page (optionally as a reply to another comment).",
    hidden: true,
    category: "Wiki"

  input do
    field :page, :string, required: true, description: "Page UUID"
    field :content, :string, required: true, description: "Comment content (markdown)"
    field :author, :string, description: "Author label (defaults to \"mcp\")"
    field :reply_to, :string, description: "Optional comment UUID to reply to (threading)"
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
          reply_to_id: Args.get(args, :reply_to),
          author: Args.get(args, :author) || "mcp",
          content: Args.get(args, :content)
        }

        case Wiki.create_comment(attrs) do
          {:ok, comment} ->
            {:ok, %{id: comment.id, page_id: page.id, author: comment.author, content: comment.content, reply_to_id: comment.reply_to_id}}

          {:error, changeset} ->
            {:error, "Failed: #{inspect(changeset.errors)}"}
        end
    end
  end
end
