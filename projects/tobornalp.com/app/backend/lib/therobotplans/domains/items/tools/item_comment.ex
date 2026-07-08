defmodule Therobotplans.Domains.Items.Tools.ItemComment do
  use Noizu.MCP.Server.Tool,
    name: "Item.Comment",
    description: "Add a comment to an item or list existing comments.",
    hidden: true,
    category: "Items"

  input do
    field :item_id, :string, required: true, description: "Item UUID"
    field :action, :string, description: "\"add\" (default) or \"list\""
    field :content, :string, description: "Comment content (markdown) — required for add"
    field :author, :string, description: "Author persona slug"
    field :reply_to_id, :string, description: "UUID of comment to reply to (threading)"
  end

  alias Therobotplans.Services.Comment

  @impl true
  def call(args, _ctx) do
    item_id = args[:item_id] || args["item_id"]
    action = args[:action] || args["action"] || "add"

    case action do
      "list" ->
        comments = Comment.list("item", item_id)

        {:ok,
         %{
           item_id: item_id,
           comments:
             Enum.map(comments, fn c ->
               %{
                 id: c.id,
                 content: c.content,
                 author: c.author,
                 reply_to_id: c.reply_to_id,
                 created_at: c.inserted_at
               }
             end)
         }}

      _ ->
        attrs = %{
          content: args[:content] || args["content"],
          author: args[:author] || args["author"],
          reply_to_id: args[:reply_to_id] || args["reply_to_id"]
        }

        case Comment.add("item", item_id, attrs) do
          {:ok, comment} ->
            {:ok, %{id: comment.id, item_id: item_id, content: comment.content}}

          {:error, changeset} ->
            {:error, "Failed: #{inspect(changeset.errors)}"}
        end
    end
  end
end
