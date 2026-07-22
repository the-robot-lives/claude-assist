defmodule ForyouWeb.ListsController do
  @moduledoc """
  Authenticated (JWT) project-scoped reads for the admin console. Permissions
  inherit through the parent Service (project) — `list:view` / `signup:list`
  checked via `Foryou.Authz.check_permission/4` with resource_type `"project"`
  (no new resource_type; D-B/PBAC). Writes are the system-level management API
  (TF) — not here.
  """
  use ForyouWeb, :controller

  alias Foryou.{Lists, Repo, Signups}

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
        q: params["q"],
        limit: parse_int(params["limit"], 50),
        offset: parse_int(params["offset"], 0)
      ]

      rows = Signups.list_signups(list.id, opts)
      total = Signups.count_signups(list.id, status: params["status"], q: params["q"])

      json(conn, %{
        signups: Enum.map(rows, &serialize_signup/1),
        attributes: attribute_schema(list.id),
        pagination: %{limit: opts[:limit], offset: opts[:offset], total: total}
      })
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      other -> other
    end
  end

  # Streamed, filter-honoring CSV of a list's signups (D5). One column per
  # declared attribute + standard columns; RFC-4180, UTF-8 w/ BOM.
  def export_signups(conn, %{"id" => id} = params) do
    with %{} = list <- Lists.get_list(id),
         :ok <- authorize(conn, "project", list.project_id, "signup:list") do
      stream_csv(conn, list, params)
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
      opt_in_mode: to_string(Signups.opt_in_mode(l)),
      attribute_count: length(Lists.list_attributes(l.id)),
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

  # Declared-attribute schema for the admin table's dynamic columns / exporter.
  defp attribute_schema(list_id) do
    Lists.list_attributes(list_id)
    |> Enum.map(fn a -> %{key: a.slug, label: a.name, type: a.type, required: a.required} end)
  end

  # ── CSV export (streamed, RFC-4180, UTF-8 w/ BOM — D5) ──────────

  defp stream_csv(conn, list, params) do
    attr_slugs = Lists.list_attributes(list.id) |> Enum.map(& &1.slug)
    headers = ["email", "status", "source", "created_at"] ++ attr_slugs
    filename = "signups-#{list.slug}-#{Date.utc_today()}.csv"

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
      |> send_chunked(200)

    # UTF-8 BOM (D5) + header row.
    {:ok, conn} = chunk(conn, <<0xEF, 0xBB, 0xBF>> <> csv_row(headers) <> "\r\n")

    query = Signups.export_query(list.id, status: params["status"], q: params["q"])

    Repo.transaction(fn ->
      query
      |> Repo.stream(max_rows: 500)
      |> Stream.each(fn s ->
        base = [s.email, s.status, s.source || "", to_string(s.inserted_at)]
        attrs = Enum.map(attr_slugs, fn slug -> csv_cell(Map.get(s.attribs || %{}, slug)) end)
        {:ok, _} = chunk(conn, csv_row(base ++ attrs) <> "\r\n")
      end)
      |> Stream.run()
    end)

    conn
  end

  defp csv_row(cells), do: cells |> Enum.map(&csv_escape/1) |> Enum.join(",")

  defp csv_cell(nil), do: ""
  defp csv_cell(v) when is_list(v), do: Enum.join(v, ";")
  defp csv_cell(v) when is_map(v), do: Jason.encode!(v)
  defp csv_cell(v), do: to_string(v)

  defp csv_escape(v) do
    s = csv_cell(v)

    if String.contains?(s, [",", "\"", "\n", "\r"]) do
      ~s("#{String.replace(s, "\"", "\"\"")}")
    else
      s
    end
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
