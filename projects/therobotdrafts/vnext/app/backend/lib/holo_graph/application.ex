defmodule HoloGraph.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:holo_graph, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:holo_graph, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children =
      [
        HoloGraphWeb.Telemetry,
        HoloGraph.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:holo_graph, :ecto_repos), skip: skip_migrations?()},
        {DNSCluster, query: Application.get_env(:holo_graph, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: HoloGraph.PubSub},
        HoloGraph.Redis,
        Noizu.LiveViewEventServer,
        {Oban, Application.fetch_env!(:holo_graph, Oban)}
      ] ++
        samly_children ++
        [
          HoloGraph.Events.WebhookHandler,
          HoloGraphWeb.Endpoint
        ]

    opts = [strategy: :one_for_one, name: HoloGraph.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HoloGraphWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
