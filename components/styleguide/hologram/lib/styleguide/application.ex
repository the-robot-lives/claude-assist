defmodule Styleguide.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Styleguide.PubSub},
      Styleguide.Auth.SSOCode,
      StyleguideWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Styleguide.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    StyleguideWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
