defmodule Therobotknows.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:therobotknows, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:therobotknows, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TherobotknowsWeb.Telemetry,
      Therobotknows.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:therobotknows, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:therobotknows, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Therobotknows.PubSub},
      Therobotknows.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:therobotknows, Oban)}
    ] ++ samly_children ++ [
      Therobotknows.Events.WebhookHandler,
      TherobotknowsWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Therobotknows.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TherobotknowsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
