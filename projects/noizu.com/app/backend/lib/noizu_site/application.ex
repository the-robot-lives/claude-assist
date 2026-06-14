defmodule NoizuSite.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:noizu_site, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:noizu_site, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      NoizuSiteWeb.Telemetry,
      NoizuSite.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:noizu_site, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:noizu_site, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: NoizuSite.PubSub},
      NoizuSite.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:noizu_site, Oban)}
    ] ++ samly_children ++ [
      NoizuSite.Events.WebhookHandler,
      NoizuSiteWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: NoizuSite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    NoizuSiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
