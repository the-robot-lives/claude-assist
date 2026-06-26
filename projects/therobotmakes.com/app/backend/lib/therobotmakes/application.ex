defmodule Therobotmakes.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:therobotmakes, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:therobotmakes, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TherobotmakesWeb.Telemetry,
      Therobotmakes.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:therobotmakes, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:therobotmakes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Therobotmakes.PubSub},
      Therobotmakes.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:therobotmakes, Oban)}
    ] ++ samly_children ++ [
      Therobotmakes.Events.WebhookHandler,
      TherobotmakesWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Therobotmakes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TherobotmakesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
