defmodule ForyouWeb.ListsController do
  @moduledoc """
  Authenticated (JWT) project-scoped reads for the admin console. Permissions
  inherit through the parent Service (project) — `list:view` / `signup:list`
  checked via `Foryou.Authz.check_permission/4` with resource_type `"project"`
  (no new resource_type; D-B/PBAC). Writes are the system-level management API
  (TF) — not here.
  """
  use ForyouWeb, :controller

  alias Foryou.{Lists, Signups}

  def index(conn, %{"project_id" => project_id}) do
    with :ok <- authorize(conn, "project", project_id, "list:view") do
      lists = Lists.list_lists(project_id)
      json(conn, %{lists: Enum.map(lists, &serialize/1)})
    end
  end

  def show(conn, %{"id" => id}) do
    with %{} = list <- Lists.get_list(id),
         :ok <- authorize(conn, "project", list.project_id, "list:view") do
      json(conn, %{list: serialize(list)})
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      other -> other
    end
  end

  def signups(conn, %{"id" => id} = params) do
    with %{} = list <- Lists.get_list(id),
         :ok <- authorize(conn, "project", list.project_id, "signup:list") do
      opts = [
        status: params["status"],
        limit: parse_int(params["limit"], 50),
        offset: parse_int(params["offset"], 0)
      ]

      rows = Signups.list_signups(list.id, opts)
      total = Signups.count_signups(list.id, status: params["status"])

      json(conn, %{
        signups: Enum.map(rows, &serialize_signup/1),
        pagination: %{limit: opts[:limit], offset: opts[:offset], total: total}
      })
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      other -> other
    end
  end

  # ── auth ───────────────────────────────────────────────────────

  defp authorize(conn, resource_type, resource_id, action) do
    user_id = get_user_id(conn)

    cond do
      is_nil(user_id) ->
        conn |> put_status(:unauthorized) |> json(%{error: "Authentication required"})

      Foryou.Authz.check_permission(user_id, resource_type, resource_id, action) ->
        :ok

      true ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp get_user_id(conn) do
    case Foryou.Guardian.Plug.current_resource(conn) do
      %Foryou.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Foryou.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp serialize(l) do
    %{
      id: l.id,
      project_id: l.project_id,
      slug: l.slug,
      public_slug: l.public_slug,
      name: l.name,
      description: l.description,
      kind: l.kind,
      status: l.status,
      settings: l.settings,
      signup_count: Signups.count_signups(l.id)
    }
  end

  defp serialize_signup(s) do
    %{
      id: s.id,
      email: s.email,
      status: s.status,
      attribs: s.attribs,
      source: s.source,
      user_id: s.user_id,
      inserted_at: s.inserted_at
    }
  end

  defp parse_int(nil, default), do: default
  defp parse_int(v, _default) when is_integer(v), do: v

  defp parse_int(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      _ -> default
    end
  end
end
