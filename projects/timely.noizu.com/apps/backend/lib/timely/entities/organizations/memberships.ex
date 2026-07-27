defmodule Timely.Organizations.Memberships do
  @moduledoc """
  Repo for Timely.Organizations.Membership
  """
  alias Timely.Organizations.Membership, as: Entity
  alias Timely.Schema.Organizations.Membership, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓋂𓋳𓁎𓊺⟧ list_for_org :: auto-generated pointer for public function list_for_org
  def list_for_org(org_id, context, options \\ []) do
    import Ecto.Query
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Timely.Repo.all(from m in Schema, where: m.organization_id == ^org_id)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end
end
