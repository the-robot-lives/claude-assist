defmodule DesigningDerobot.Auth.Providers.Provider do
  use Noizu.Entities

  @vsn 1.0
  @repo DesigningDerobot.Auth.Providers
  @sref "auth-provider"
  @persistence ecto_store(DesigningDerobot.Schema.Auth.Providers.Provider, DesigningDerobot.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :description, nil, :string
    field :settings, %{}, :any
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
