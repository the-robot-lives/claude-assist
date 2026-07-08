defmodule Therobotplans.Domains.Notifications.Tools.Ack do
  use Noizu.MCP.Server.Tool,
    name: "Notifications.Ack",
    description:
      "Acknowledge (dismiss) notifications for a recipient so they no longer surface. Pass specific `ids`, or omit to ack all.",
    hidden: true,
    category: "Notifications"

  input do
    field :organization, :string, required: true, description: "Organization slug or UUID"
    field :recipient, :string, required: true, description: "Recipient handle"
    field :ids, {:array, :string}, description: "Notification ids to ack (omit for all)"
  end

  alias Therobotplans.Domains.Notifications
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, _ctx) do
    case Resolve.organization_id(Args.get(args, :organization)) do
      nil ->
        {:error, "Organization '#{Args.get(args, :organization)}' not found"}

      org_id ->
        ids = Args.get(args, :ids) || :all
        {:ok, count} = Notifications.ack(org_id, Args.get(args, :recipient), ids)
        {:ok, %{acked: count}}
    end
  end
end
