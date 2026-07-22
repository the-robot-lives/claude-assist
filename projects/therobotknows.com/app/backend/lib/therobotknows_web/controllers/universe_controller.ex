defmodule TherobotknowsWeb.UniverseController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Universes

  def index(conn, params) do
    user_id = get_user_id(conn)
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 25)

    result = Universes.list_for_user(user_id, page: page, per_page: per_page)

    json(conn, %{
      universes: Enum.map(result.universes, &universe_json/1),
      meta: result.meta
    })
  end

  def create(conn, %{"universe" => attrs}) do
    user_id = get_user_id(conn)

    case Universes.create_with_owner(attrs, user_id) do
      {:ok, universe} ->
        conn
        |> put_status(:created)
        |> json(%{universe: universe_json(universe)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: inspect(reason)})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "universe params required"})
  end

  def show(conn, %{"id" => id}) do
    user_id = get_user_id(conn)

    case Universes.get_for_user(id, user_id) do
      {:ok, universe} ->
        json(conn, %{universe: universe_json(universe)})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def update(conn, %{"id" => id, "universe" => attrs}) do
    user_id = get_user_id(conn)

    case Universes.update_for_user(id, attrs, user_id) do
      {:ok, universe} ->
        json(conn, %{universe: universe_json(universe)})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => _id}) do
    conn |> put_status(:bad_request) |> json(%{error: "universe params required"})
  end

  def delete(conn, %{"id" => id}) do
    user_id = get_user_id(conn)

    case Universes.delete_for_user(id, user_id) do
      {:ok, _} ->
        json(conn, %{message: "Universe deleted"})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Only the owner can delete a universe"})
    end
  end

  def stats(conn, %{"id" => id}) do
    user_id = get_user_id(conn)

    case Universes.stats_for_user(id, user_id) do
      {:ok, stats} ->
        json(conn, %{stats: stats})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def members(conn, %{"id" => id}) do
    user_id = get_user_id(conn)

    case Universes.list_members(id, user_id) do
      {:ok, members} ->
        json(conn, %{members: members})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  defp universe_json(u) when is_map(u) do
    %{
      id: u[:id] || u["id"],
      slug: u[:slug] || u["slug"],
      name: u[:name] || u["name"],
      description: u[:description] || u["description"],
      genre: u[:genre] || u["genre"],
      tone: u[:tone] || u["tone"],
      config: u[:config] || u["config"] || %{},
      status: u[:status] || u["status"],
      entry_count: u[:entry_count] || u["entry_count"] || 0,
      flag_count: u[:flag_count] || u["flag_count"] || 0,
      connection_count: u[:connection_count] || u["connection_count"] || 0,
      role: u[:role] || u["role"],
      created_by: u[:created_by] || u["created_by"],
      inserted_at: u[:inserted_at] || u["inserted_at"],
      updated_at: u[:updated_at] || u["updated_at"]
    }
  end

  defp get_user_id(conn) do
    case Therobotknows.Guardian.Plug.current_resource(conn) do
      %Therobotknows.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotknows.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_int(val, default) when is_integer(val) and val > 0, do: val
  defp parse_int(_, default), do: default
end
