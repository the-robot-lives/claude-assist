defmodule Aifighter.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:aifighter, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:aifighter, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      AifighterWeb.Telemetry,
      Aifighter.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:aifighter, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:aifighter, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Aifighter.PubSub},
      Aifighter.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:aifighter, Oban)}
    ] ++ samly_children ++ [
      Aifighter.Events.WebhookHandler,
      AifighterWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Aifighter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AifighterWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
