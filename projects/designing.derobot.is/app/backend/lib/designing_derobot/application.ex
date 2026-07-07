defmodule DesigningDerobot.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:designing_derobot, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:designing_derobot, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      DesigningDerobotWeb.Telemetry,
      DesigningDerobot.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:designing_derobot, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:designing_derobot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DesigningDerobot.PubSub},
      DesigningDerobot.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:designing_derobot, Oban)}
    ] ++ samly_children ++ [
      DesigningDerobot.Events.WebhookHandler,
      DesigningDerobotWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: DesigningDerobot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    DesigningDerobotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
