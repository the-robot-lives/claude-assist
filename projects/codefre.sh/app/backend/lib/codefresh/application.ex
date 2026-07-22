defmodule Codefresh.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:codefresh, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:codefresh, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children =
      [
        CodefreshWeb.Telemetry,
        Codefresh.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:codefresh, :ecto_repos), skip: skip_migrations?()},
        {DNSCluster, query: Application.get_env(:codefresh, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Codefresh.PubSub},
        Codefresh.Redis,
        Noizu.LiveViewEventServer,
        {Oban, Application.fetch_env!(:codefresh, Oban)}
      ] ++
        samly_children ++
        maybe_scheduler_ticker() ++
        [
          Codefresh.Events.WebhookHandler,
          CodefreshWeb.Endpoint
        ]

    opts = [strategy: :one_for_one, name: Codefresh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CodefreshWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end

  # US-069: start the scheduled-run ticker outside of tests. Tests drive the
  # scheduler deterministically via `Codefresh.Runs.Scheduler.tick/1`.
  defp maybe_scheduler_ticker do
    if Application.get_env(:codefresh, :start_scheduler_ticker, true) do
      [Codefresh.Runs.Scheduler.Ticker]
    else
      []
    end
  end
end
