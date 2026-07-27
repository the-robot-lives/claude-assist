defmodule Timely.Release do
  @moduledoc """
  Schema migrations are handled by Liquibase (see backend/db/).
  This module provides seed running for releases.
  """
  @app :timely

  # ⟦𓍓𓄝𓈨𓆪⟧ migrate :: auto-generated pointer for public function migrate
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  # ⟦𓂶𓃬𓍯𓈄⟧ rollback :: auto-generated pointer for public function rollback
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # ⟦𓍐𓋒𓉆𓀒⟧ seed :: auto-generated pointer for public function seed
  def seed do
    load_app()

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
