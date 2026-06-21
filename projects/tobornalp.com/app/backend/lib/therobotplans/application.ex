defmodule Therobotplans.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:therobotplans, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:therobotplans, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TherobotplansWeb.Telemetry,
      Therobotplans.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:therobotplans, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:therobotplans, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Therobotplans.PubSub},
      Therobotplans.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:therobotplans, Oban)}
    ] ++ samly_children ++ [
      Therobotplans.Events.WebhookHandler,
      TherobotplansWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Therobotplans.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TherobotplansWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
