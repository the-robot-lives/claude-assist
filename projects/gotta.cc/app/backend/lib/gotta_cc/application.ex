defmodule GottaCc.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:gotta_cc, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:gotta_cc, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      GottaCcWeb.Telemetry,
      GottaCc.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:gotta_cc, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:gotta_cc, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GottaCc.PubSub},
      GottaCc.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:gotta_cc, Oban)}
    ] ++ samly_children ++ [
      GottaCc.Events.WebhookHandler,
      GottaCcWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: GottaCc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GottaCcWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
