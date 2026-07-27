defmodule Timely.Authz.Policies.Policy do
  use Noizu.Entities

  @vsn 1.0
  @repo Timely.Authz.Policies
  @sref "authz-policy"
  @persistence ecto_store(Timely.Schema.Authz.Policy, Timely.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :name, nil, :string
    field :description, nil, :string
    field :policy_document, %{}, :map
    field :is_system, false, :boolean
    field :is_active, true, :boolean
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use Timely.Support.NoizuJasonEncoder
end
