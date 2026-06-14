defmodule Therobotlives.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:therobotlives, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:therobotlives, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TherobotlivesWeb.Telemetry,
      Therobotlives.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:therobotlives, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:therobotlives, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Therobotlives.PubSub},
      Therobotlives.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:therobotlives, Oban)}
    ] ++ samly_children ++ [
      Therobotlives.Events.WebhookHandler,
      TherobotlivesWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Therobotlives.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TherobotlivesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
