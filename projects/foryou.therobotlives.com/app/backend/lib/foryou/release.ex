defmodule Foryou.Release do
  @moduledoc """
  Schema migrations are handled by Liquibase (see backend/db/).
  This module provides seed running for releases.
  """
  @app :foryou

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed(env \\ System.get_env("SEED_ENV") || "prod") do
    load_app()
    # Accept atom (:prod) or string ("prod") — normalize to a string once.
    env = to_string(env)
    System.put_env("SEED_ENV", env)

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          Code.eval_file(Path.join([:code.priv_dir(@app), "repo", "seeds.exs"]))
        end)
    end
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
