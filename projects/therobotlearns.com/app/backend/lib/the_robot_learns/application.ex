defmodule TheRobotLearns.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:the_robot_learns, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:the_robot_learns, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children =
      [
        TheRobotLearnsWeb.Telemetry,
        TheRobotLearns.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:the_robot_learns, :ecto_repos), skip: skip_migrations?()},
        {DNSCluster, query: Application.get_env(:the_robot_learns, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: TheRobotLearns.PubSub},
        TheRobotLearns.Redis,
        Noizu.LiveViewEventServer,
        {Oban, Application.fetch_env!(:the_robot_learns, Oban)}
      ] ++
        samly_children ++
        [
          TheRobotLearns.Events.WebhookHandler,
          TheRobotLearnsWeb.Endpoint
        ]

    opts = [strategy: :one_for_one, name: TheRobotLearns.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TheRobotLearnsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
