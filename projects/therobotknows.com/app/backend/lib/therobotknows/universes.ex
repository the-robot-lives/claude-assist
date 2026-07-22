defmodule Therobotknows.Universes do
  @moduledoc """
  Universe CRUD and membership (KB domain). Membership-based ownership per ADR-008.
  """

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Schema.Universe.{Universe, Member}
  alias Therobotknows.Schema.Canon.{Entry, EntryLink}

  @write_roles ~w(owner editor)
  @owner_roles ~w(owner)

  def list_for_user(user_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = min(Keyword.get(opts, :per_page, 25), 100)
    offset = (page - 1) * per_page

    total =
      from(u in Universe,
        join: m in Member,
        on: m.universe_id == u.id and m.user_id == ^user_id,
        where: u.status == "active",
        select: count(u.id)
      )
      |> Repo.one() || 0

    rows =
      from(u in Universe,
        join: m in Member,
        on: m.universe_id == u.id and m.user_id == ^user_id,
        where: u.status == "active",
        order_by: [desc: u.updated_at],
        select: {u, m.role},
        limit: ^per_page,
        offset: ^offset
      )
      |> Repo.all()

    universes =
      Enum.map(rows, fn {universe, role} ->
        universe
        |> with_counts()
        |> Map.put(:role, role)
      end)

    %{
      universes: universes,
      meta: %{
        page: page,
        per_page: per_page,
        total: total,
        total_pages: max(1, ceil(total / per_page))
      }
    }
  end

  def get_for_user(id_or_slug, user_id) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, role} <- member_role(universe.id, user_id) do
      {:ok, universe |> with_counts() |> Map.put(:role, role)}
    end
  end

  def create_with_owner(attrs, user_id) do
    slug = Map.get(attrs, "slug") || Map.get(attrs, :slug) || slugify(Map.get(attrs, "name") || Map.get(attrs, :name))

    config =
      Map.get(attrs, "config") || Map.get(attrs, :config) || %{}

    genre = Map.get(attrs, "genre") || Map.get(attrs, :genre) || Map.get(config, "genre")
    tone = Map.get(attrs, "tone") || Map.get(attrs, :tone) || Map.get(config, "tone")

    config =
      config
      |> Map.put_new("genre", genre)
      |> Map.put_new("tone", tone)

    Repo.transaction(fn ->
      cs =
        %Universe{}
        |> Universe.changeset(%{
          name: Map.get(attrs, "name") || Map.get(attrs, :name),
          slug: slug,
          description: Map.get(attrs, "description") || Map.get(attrs, :description),
          genre: genre,
          tone: tone,
          config: stringify_keys(config),
          created_by: user_id,
          status: "active"
        })

      case Repo.insert(cs) do
        {:ok, universe} ->
          member_cs =
            %Member{}
            |> Member.changeset(%{
              universe_id: universe.id,
              user_id: user_id,
              role: "owner"
            })

          case Repo.insert(member_cs) do
            {:ok, _} ->
              universe
              |> with_counts()
              |> Map.put(:role, "owner")

            {:error, reason} ->
              Repo.rollback(reason)
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def update_for_user(id_or_slug, attrs, user_id) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, role} <- member_role(universe.id, user_id),
         :ok <- authorize_write(role) do
      config =
        case Map.get(attrs, "config") || Map.get(attrs, :config) do
          nil -> universe.config
          c -> Map.merge(universe.config || %{}, stringify_keys(c))
        end

      genre =
        Map.get(attrs, "genre") || Map.get(attrs, :genre) || Map.get(config, "genre") ||
          universe.genre

      tone =
        Map.get(attrs, "tone") || Map.get(attrs, :tone) || Map.get(config, "tone") ||
          universe.tone

      updates =
        %{}
        |> maybe_put(:name, Map.get(attrs, "name") || Map.get(attrs, :name))
        |> maybe_put(:description, Map.get(attrs, "description") || Map.get(attrs, :description))
        |> Map.put(:genre, genre)
        |> Map.put(:tone, tone)
        |> Map.put(:config, config)

      case universe |> Universe.changeset(updates) |> Repo.update() do
        {:ok, updated} -> {:ok, updated |> with_counts() |> Map.put(:role, role)}
        error -> error
      end
    end
  end

  def delete_for_user(id_or_slug, user_id) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, role} <- member_role(universe.id, user_id),
         :ok <- authorize_owner(role) do
      universe |> Universe.soft_delete_changeset() |> Repo.update()
    end
  end

  def stats_for_user(id_or_slug, user_id) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, _role} <- member_role(universe.id, user_id) do
      entry_counts_by_type =
        from(e in Entry,
          where: e.universe_id == ^universe.id and is_nil(e.deleted_at),
          group_by: e.type,
          select: {e.type, count(e.id)}
        )
        |> Repo.all()
        |> Map.new()

      entry_counts_by_status =
        from(e in Entry,
          where: e.universe_id == ^universe.id and is_nil(e.deleted_at),
          group_by: e.status,
          select: {e.status, count(e.id)}
        )
        |> Repo.all()
        |> Map.new()

      entry_count = entry_counts_by_status |> Map.values() |> Enum.sum()

      connection_count =
        from(l in EntryLink, where: l.universe_id == ^universe.id)
        |> Repo.aggregate(:count, :id)

      {:ok,
       %{
         entry_count: entry_count,
         entry_counts_by_type: entry_counts_by_type,
         entry_counts_by_status: entry_counts_by_status,
         flag_count: 0,
         flag_counts_by_severity: %{},
         connection_count: connection_count,
         recent_activity: []
       }}
    end
  end

  def list_members(id_or_slug, user_id) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, _role} <- member_role(universe.id, user_id) do
      members =
        from(m in Member,
          join: u in Therobotknows.Schema.Users.User,
          on: u.id == m.user_id,
          where: m.universe_id == ^universe.id,
          select: %{
            id: m.id,
            user_id: m.user_id,
            email: u.email,
            user_name: u.user_name,
            role: m.role,
            joined_at: m.inserted_at
          }
        )
        |> Repo.all()

      {:ok, members}
    end
  end

  def authorize(id_or_slug, user_id, min_role \\ :viewer) do
    with {:ok, universe} <- get_active(id_or_slug),
         {:ok, role} <- member_role(universe.id, user_id),
         :ok <- role_allows?(role, min_role) do
      {:ok, universe, role}
    end
  end

  def get_active(id_or_slug) do
    query =
      if uuid?(id_or_slug) do
        from u in Universe, where: u.id == ^id_or_slug and u.status == "active"
      else
        from u in Universe, where: u.slug == ^id_or_slug and u.status == "active"
      end

    case Repo.one(query) do
      nil -> {:error, :not_found}
      universe -> {:ok, universe}
    end
  end

  def member_role(universe_id, user_id) do
    case Repo.get_by(Member, universe_id: universe_id, user_id: user_id) do
      nil -> {:error, :forbidden}
      %Member{role: role} -> {:ok, role}
    end
  end

  defp with_counts(%Universe{} = universe) do
    entry_count =
      from(e in Entry,
        where: e.universe_id == ^universe.id and is_nil(e.deleted_at)
      )
      |> Repo.aggregate(:count, :id)

    connection_count =
      from(l in EntryLink, where: l.universe_id == ^universe.id)
      |> Repo.aggregate(:count, :id)

    universe
    |> Map.from_struct()
    |> Map.drop([:__meta__, :members])
    |> Map.put(:entry_count, entry_count)
    |> Map.put(:flag_count, 0)
    |> Map.put(:connection_count, connection_count)
  end

  defp authorize_write(role) when role in @write_roles, do: :ok
  defp authorize_write(_), do: {:error, :forbidden}

  defp authorize_owner(role) when role in @owner_roles, do: :ok
  defp authorize_owner(_), do: {:error, :forbidden}

  defp role_allows?(_role, :viewer), do: :ok
  defp role_allows?(role, :editor) when role in @write_roles, do: :ok
  defp role_allows?(role, :owner) when role in @owner_roles, do: :ok
  defp role_allows?(_, _), do: {:error, :forbidden}

  defp slugify(nil), do: "universe-#{System.unique_integer([:positive])}"

  defp slugify(name) when is_binary(name) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    if base == "", do: "universe-#{System.unique_integer([:positive])}", else: base
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp stringify_keys(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp uuid?(value) when is_binary(value) do
    match?({:ok, _}, Ecto.UUID.cast(value))
  end

  defp uuid?(_), do: false
end
