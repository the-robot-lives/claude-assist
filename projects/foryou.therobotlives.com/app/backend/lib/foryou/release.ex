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

  @doc """
  Mints an API key owned by a bootstrap system user (created idempotently).
  Prints the plaintext secret once. Invoke from a release:

      bin/foryou eval 'Foryou.Release.mint_api_key("terraform")'
  """
  def mint_api_key(name, owner_role \\ "system") do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          user_id = ensure_system_user!(owner_role)

          case Foryou.Auth.ApiKeys.mint(user_id, name) do
            {:ok, _key, secret} ->
              IO.puts("API KEY (store securely — shown once):")
              IO.puts(secret)

            {:error, changeset} ->
              IO.puts("Failed to mint API key:")
              IO.inspect(changeset.errors)
          end
        end)
    end

    :ok
  end

  defp ensure_system_user!(role) do
    alias Foryou.Schema.Users.User
    alias Foryou.Schema.Versioned.Names.Name
    alias Foryou.Schema.Versioned.Descriptions.Description

    user_id = UUID.uuid5(:oid, "Foryou.Schema.Users.User@System:#{role}")

    if Foryou.Repo.get(User, user_id) == nil do
      name_id = UUID.uuid5(:oid, "Foryou.Versioned.Names.Name@System:#{role}")
      desc_id = UUID.uuid5(:oid, "Foryou.Versioned.Descriptions.Description@System:#{role}")

      Foryou.Repo.insert!(%Name{id: name_id, first: role, middle: [], last: "System"},
        on_conflict: :nothing,
        conflict_target: :id
      )

      Foryou.Repo.insert!(
        %Description{id: desc_id, title: "System", body: ""},
        on_conflict: :nothing,
        conflict_target: :id
      )

      Foryou.Repo.insert!(
        %User{
          id: user_id,
          user_name: role,
          handle: role,
          name_id: name_id,
          description_id: desc_id,
          email: "#{role}@foryou.local",
          status: :active,
          verified: true,
          flagged: false
        },
        on_conflict: :nothing,
        conflict_target: :id
      )
    end

    user_id
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
