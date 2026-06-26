defmodule Therobotsdayjob.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:therobotsdayjob, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:therobotsdayjob, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TherobotsdayjobWeb.Telemetry,
      Therobotsdayjob.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:therobotsdayjob, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:therobotsdayjob, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Therobotsdayjob.PubSub},
      Therobotsdayjob.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:therobotsdayjob, Oban)}
    ] ++ samly_children ++ [
      Therobotsdayjob.Events.WebhookHandler,
      TherobotsdayjobWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Therobotsdayjob.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TherobotsdayjobWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
