defmodule Timely.Authz.Groups do
  alias Timely.Authz.Groups.Group, as: Entity
  alias Timely.Schema.Authz.Group, as: Schema
  alias Timely.Schema.Authz.GroupPolicy, as: GroupPolicySchema
  alias Timely.Schema.Authz.Policy, as: PolicySchema

  use Noizu.Repo
  def_repo(entity: Entity)

  import Ecto.Query

  # ⟦𓍉𓂐𓌘𓌃⟧ list_all :: auto-generated pointer for public function list_all
  def list_all do
    Timely.Repo.all(from g in Schema, order_by: g.name)
  end

  # ⟦𓍲𓆡𓄷𓆝⟧ get_by_name :: auto-generated pointer for public function get_by_name
  def get_by_name(name) when is_binary(name) do
    Timely.Repo.one(from g in Schema, where: g.name == ^name)
  end

  # ⟦𓁎𓁖𓋢𓎊⟧ list_policies :: auto-generated pointer for public function list_policies
  def list_policies(group_id) do
    from(gp in GroupPolicySchema,
      join: p in PolicySchema,
      on: p.id == gp.policy_id,
      where: gp.group_id == ^group_id,
      order_by: gp.priority,
      select: %{
        id: p.id,
        name: p.name,
        description: p.description,
        policy_document: p.policy_document,
        is_system: p.is_system,
        is_active: p.is_active,
        priority: gp.priority
      }
    )
    |> Timely.Repo.all()
  end
end
