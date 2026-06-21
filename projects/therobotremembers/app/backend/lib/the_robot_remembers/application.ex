defmodule TheRobotRemembers.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:the_robot_remembers, :repo])
    OpentelemetryBandit.setup()

    samly_children =
      if Application.get_env(:the_robot_remembers, :saml_enabled) do
        [Samly.Provider]
      else
        []
      end

    children = [
      TheRobotRemembersWeb.Telemetry,
      TheRobotRemembers.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:the_robot_remembers, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:the_robot_remembers, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TheRobotRemembers.PubSub},
      TheRobotRemembers.Redis,
      Noizu.LiveViewEventServer,
      {Oban, Application.fetch_env!(:the_robot_remembers, Oban)}
    ] ++ samly_children ++ [
      TheRobotRemembers.Events.WebhookHandler,
      # MCP server (component registry for the Streamable-HTTP transport mounted in the router)
      TheRobotRemembers.MCP,
      TheRobotRemembersWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TheRobotRemembers.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TheRobotRemembersWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") == nil
  end
end
