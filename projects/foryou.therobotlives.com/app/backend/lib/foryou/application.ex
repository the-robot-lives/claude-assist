defmodule Foryou.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:foryou, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:foryou, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      ForyouWeb.Telemetry,
      Foryou.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:foryou, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:foryou, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Foryou.PubSub},
      Foryou.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:foryou, Oban)}
    ] ++ samly_children ++ [
      Foryou.Events.WebhookHandler,
      ForyouWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Foryou.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ForyouWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
