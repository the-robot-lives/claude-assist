defmodule HoloGraph.Auth.Providers.Provider do
  use Noizu.Entities

  @vsn 1.0
  @repo HoloGraph.Auth.Providers
  @sref "auth-provider"
  @persistence ecto_store(HoloGraph.Schema.Auth.Providers.Provider, HoloGraph.Repo)
  use Noizu.Entity.Store.Ecto.EntityProtocol.Behaviour

  def_entity do
    id(:uuid)
    field :title, nil, :string
    field :description, nil, :string
    field :settings, %{}, :any
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  use HoloGraph.Support.NoizuJasonEncoder
end
