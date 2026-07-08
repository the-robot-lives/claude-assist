defmodule Therobotplans.Domains.Goals.Tools.Overview do
  use Noizu.MCP.Server.Tool,
    name: "Goals.Overview",
    description: "List the Goals tools and active objective count for an organization.",
    annotations: [read_only_hint: true],
    category: "Goals"

  import Ecto.Query
  alias Therobotplans.Schema.Objective
  alias Therobotplans.MCP.{Args, Resolve}

  input do
    field :organization, :string, required: true, description: "Organization slug or UUID"
  end

  @impl true
  def call(args, _ctx) do
    case Resolve.organization_id(Args.get(args, :organization)) do
      nil ->
        {:error, "Organization '#{Args.get(args, :organization)}' not found"}

      org_id ->
        active =
          Therobotplans.Repo.aggregate(
            from(o in Objective, where: o.organization_id == ^org_id and o.status == "active"),
            :count
          )

        {:ok,
         %{
           domain: "Goals",
           organization_id: org_id,
           active_objectives: active,
           tools: %{
             objectives: ~w(Objective.Create Objective.Get Objective.Update Objective.List),
             key_results:
               ~w(KeyResult.Create KeyResult.Update KeyResult.LinkItem KeyResult.Progress),
             checkins: ~w(Checkin.Create)
           }
         }}
    end
  end
end
