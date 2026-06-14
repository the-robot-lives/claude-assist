defmodule Iotgo.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:iotgo, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:iotgo, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      IotgoWeb.Telemetry,
      Iotgo.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:iotgo, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:iotgo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Iotgo.PubSub},
      Iotgo.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:iotgo, Oban)}
    ] ++ samly_children ++ [
      Iotgo.Events.WebhookHandler,
      IotgoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Iotgo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    IotgoWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
