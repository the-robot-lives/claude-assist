defmodule TherobotknowsWeb.EntryController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Canon

  def index(conn, %{"universe_id" => universe_id} = params) do
    user_id = get_user_id(conn)

    opts = [
      page: parse_int(params["page"], 1),
      per_page: parse_int(params["per_page"], 25),
      type: params["type"],
      status: params["status"],
      tag: params["tag"],
      era: params["era"],
      region: params["region"],
      q: params["q"]
    ]

    case Canon.list_entries(universe_id, user_id, opts) do
      {:ok, result} ->
        json(conn, result)

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def create(conn, %{"universe_id" => universe_id, "entry" => attrs}) do
    user_id = get_user_id(conn)

    case Canon.create_entry(universe_id, attrs, user_id) do
      {:ok, entry} ->
        conn |> put_status(:created) |> json(%{entry: entry})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "entry params required"})
  end

  def show(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = get_user_id(conn)

    case Canon.get_entry(universe_id, id, user_id) do
      {:ok, entry} ->
        json(conn, %{entry: entry})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def update(conn, %{"universe_id" => universe_id, "id" => id, "entry" => attrs}) do
    user_id = get_user_id(conn)

    case Canon.update_entry(universe_id, id, attrs, user_id) do
      {:ok, entry} ->
        json(conn, %{entry: entry})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "entry params required"})
  end

  def delete(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = get_user_id(conn)

    case Canon.delete_entry(universe_id, id, user_id) do
      {:ok, _} ->
        json(conn, %{message: "Entry deleted"})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def status(conn, %{"universe_id" => universe_id, "id" => id, "status" => new_status}) do
    user_id = get_user_id(conn)

    case Canon.transition_status(universe_id, id, new_status, user_id) do
      {:ok, entry} ->
        json(conn, %{entry: entry})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

      {:error, {:invalid_transition, from, to}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid status transition from #{from} to #{to}"})
    end
  end

  def status(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "status is required"})
  end

  def links(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = get_user_id(conn)

    case Canon.list_links(universe_id, id, user_id) do
      {:ok, links} ->
        json(conn, %{links: links})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def create_link(conn, %{"universe_id" => universe_id, "id" => id, "link" => attrs}) do
    user_id = get_user_id(conn)

    case Canon.create_link(universe_id, id, attrs, user_id) do
      {:ok, link} ->
        conn |> put_status(:created) |> json(%{link: link})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def create_link(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "link params required"})
  end

  def delete_link(conn, %{"universe_id" => universe_id, "link_id" => link_id}) do
    user_id = get_user_id(conn)

    case Canon.delete_link(universe_id, link_id, user_id) do
      {:ok, _} ->
        json(conn, %{message: "Link deleted"})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Link not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def tags(conn, %{"universe_id" => universe_id}) do
    user_id = get_user_id(conn)

    case Canon.list_tags(universe_id, user_id) do
      {:ok, tags} ->
        json(conn, %{tags: tags})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def create_tag(conn, %{"universe_id" => universe_id, "tag" => attrs}) do
    user_id = get_user_id(conn)

    case Canon.create_tag(universe_id, attrs, user_id) do
      {:ok, tag} ->
        conn |> put_status(:created) |> json(%{tag: tag})

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

  def replace_tags(conn, %{"universe_id" => universe_id, "id" => id, "tag_names" => tag_names}) do
    user_id = get_user_id(conn)

    case Canon.replace_entry_tags(universe_id, id, tag_names, user_id) do
      {:ok, entry} ->
        json(conn, %{entry: entry})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def templates(conn, _params) do
    json(conn, %{templates: Canon.list_templates()})
  end

  def search(conn, %{"universe_id" => universe_id} = params) do
    user_id = get_user_id(conn)

    opts = [
      q: params["q"] || "",
      page: parse_int(params["page"], 1),
      per_page: parse_int(params["per_page"], 25),
      type: params["type"],
      status: params["status"],
      tag: params["tag"],
      era: params["era"],
      region: params["region"]
    ]

    case Canon.search(universe_id, user_id, opts) do
      {:ok, result} ->
        json(conn, result)

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def versions(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = get_user_id(conn)

    case Canon.list_versions(universe_id, id, user_id) do
      {:ok, versions} ->
        json(conn, %{versions: versions})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Entry not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def show_version(conn, %{"universe_id" => universe_id, "id" => id, "version" => version}) do
    user_id = get_user_id(conn)
    version_num = parse_int(version, 0)

    case Canon.get_version(universe_id, id, version_num, user_id) do
      {:ok, version} ->
        json(conn, %{version: version})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Version not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
  end

  def restore_version(conn, %{"universe_id" => universe_id, "id" => id, "version" => version}) do
    user_id = get_user_id(conn)
    version_num = parse_int(version, 0)

    case Canon.restore_version(universe_id, id, version_num, user_id) do
      {:ok, entry} ->
        json(conn, %{entry: entry})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Version not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def export(conn, %{"universe_id" => universe_id} = params) do
    user_id = get_user_id(conn)
    format = params["format"] || "json"

    case Canon.export_universe(universe_id, user_id, format) do
      {:ok, :json, body} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, body)

      {:ok, :markdown, body} ->
        conn
        |> put_resp_content_type("text/markdown")
        |> send_resp(200, body)

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this universe"})
    end
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
