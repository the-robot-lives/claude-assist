defmodule Therobotplans.Domains.Goals.Tools.CheckinCreate do
  use Noizu.MCP.Server.Tool,
    name: "Checkin.Create",
    description: "Post a check-in (status update) on an objective.",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.{Args, Resolve}

  input do
    field :objective, :string, required: true, description: "Objective UUID"
    field :body, :string, required: true, description: "Check-in body"
    field :period, :string, description: "Period e.g. 2026-W30"
    field :author_id, :string, description: "Author user UUID (defaults to the caller)"
  end

  @impl true
  def call(args, ctx) do
    attrs = %{
      objective_id: Args.get(args, :objective),
      body: Args.get(args, :body),
      period: Args.get(args, :period),
      author_id: Args.get(args, :author_id) || Resolve.current_user_id(ctx)
    }

    case Goals.create_checkin(attrs) do
      {:ok, c} -> {:ok, %{id: c.id, objective_id: c.objective_id, body: c.body}}
      {:error, cs} -> {:error, "Failed: #{inspect(cs.errors)}"}
    end
  end
end
