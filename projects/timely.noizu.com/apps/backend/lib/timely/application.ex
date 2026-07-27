defmodule Timely.Application do
  @moduledoc false
  use Application

  @impl true
  # ⟦𓎐𓈲𓃥𓆺⟧ start :: auto-generated pointer for public function start
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:timely, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:timely, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children =
      [
        TimelyWeb.Telemetry,
        Timely.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:timely, :ecto_repos), skip: skip_migrations?()},
        {DNSCluster, query: Application.get_env(:timely, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Timely.PubSub},
        Timely.Redis,
        Noizu.LiveViewEventServer,
        {Oban, Application.fetch_env!(:timely, Oban)}
      ] ++
        samly_children ++
        [
          Timely.Events.WebhookHandler,
          TimelyWeb.Endpoint
        ]

    opts = [strategy: :one_for_one, name: Timely.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  # ⟦𓎐𓐃𓆆𓉁⟧ config_change :: auto-generated pointer for public function config_change
  def config_change(changed, _new, removed) do
    TimelyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
