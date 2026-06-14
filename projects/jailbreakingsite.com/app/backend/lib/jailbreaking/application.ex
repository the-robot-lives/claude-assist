defmodule Jailbreaking.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:jailbreaking, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:jailbreaking, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      JailbreakingWeb.Telemetry,
      Jailbreaking.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:jailbreaking, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:jailbreaking, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Jailbreaking.PubSub},
      Jailbreaking.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:jailbreaking, Oban)}
    ] ++ samly_children ++ [
      Jailbreaking.Events.WebhookHandler,
      JailbreakingWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Jailbreaking.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    JailbreakingWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
