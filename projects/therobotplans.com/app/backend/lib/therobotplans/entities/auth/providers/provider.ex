defmodule Therobotplans.Auth.Providers.Provider do
  use Noizu.Entities

  @vsn 1.0
  @repo Therobotplans.Auth.Providers
  @sref "auth-provider"
  @persistence ecto_store(Therobotplans.Schema.Auth.Providers.Provider, Therobotplans.Repo)
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
