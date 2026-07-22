defmodule ForyouWeb.Management.ListsController do
  @moduledoc """
  Management CRUD for lists (API-key / system-level; no PBAC — this is the
  Terraform-provider + backfill surface). `create`/`update` accept the list
  fields plus an optional `attributes` array that is idempotently upserted by
  slug, so re-applying the same spec is stable (US-036). `delete` archives (soft)
  rather than hard-deleting (US-098). Modeled on `Management.FormsController`.
  """
  use ForyouWeb, :controller

  alias Foryou.{Lists, Signups}
  alias Foryou.Schema.Lists.{List, ListAttribute}

  def index(conn, params) do
    lists =
      case params["project_id"] do
        nil -> Foryou.Repo.all(List)
        project_id -> Lists.list_lists(project_id)
      end

    json(conn, %{lists: Enum.map(lists, &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    case Lists.get_list(id) do
      nil -> not_found(conn)
      list -> json(conn, %{list: serialize(list)})
    end
  end

  def create(conn, %{"list" => params}) do
    project_id = params["project_id"]
    attrs = Map.take(params, ~w(slug public_slug name description kind settings status))

    case Lists.create_list(project_id, attrs) do
      {:ok, list} ->
        list = upsert_attributes(list, params["attributes"])
        conn |> put_status(:created) |> json(%{list: serialize(list)})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id, "list" => params}) do
    case Lists.get_list(id) do
      nil ->
        not_found(conn)

      list ->
        meta = Map.take(params, ~w(slug public_slug name description kind settings status))

        with {:ok, list} <- maybe_update(list, meta) do
          list = upsert_attributes(list, params["attributes"])
          json(conn, %{list: serialize(list)})
        else
          {:error, cs} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  # Archive (soft) — safe deprovision for TF removal (US-098).
  def delete(conn, %{"id" => id}) do
    case Lists.get_list(id) do
      nil ->
        not_found(conn)

      list ->
        case Lists.archive_list(list) do
          {:ok, _} -> send_resp(conn, :no_content, "")
          {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  # ── Signups export (US-098 / D5) ───────────────────────────────

  def signups(conn, %{"id" => id} = params) do
    case Lists.get_list(id) do
      nil ->
        not_found(conn)

      list ->
        opts = [
          status: params["status"],
          limit: parse_int(params["limit"], 1000),
          offset: parse_int(params["offset"], 0)
        ]

        rows = Signups.list_signups(list.id, opts)

        case params["format"] do
          "csv" -> send_csv(conn, list, rows)
          _ -> json(conn, %{signups: Enum.map(rows, &serialize_signup/1)})
        end
    end
  end

  # ── Import (listmonk backfill) ─────────────────────────────────

  def import_signups(conn, %{"id" => id} = params) do
    case Lists.get_list(id) do
      nil ->
        not_found(conn)

      list ->
        rows = params["rows"] || []

        case Foryou.Workers.ListmonkImportWorker.enqueue(list.id, rows) do
          {:ok, job} ->
            conn |> put_status(:accepted) |> json(%{accepted: true, job_id: job.id, rows: length(rows)})

          _ ->
            conn |> put_status(:accepted) |> json(%{accepted: true, rows: length(rows)})
        end
    end
  end

  # ── Helpers ────────────────────────────────────────────────────

  defp maybe_update(list, meta) when meta == %{}, do: {:ok, list}
  defp maybe_update(list, meta), do: Lists.update_list(list, meta)

  defp upsert_attributes(list, attributes) when is_list(attributes) do
    Enum.each(attributes, fn attr -> Lists.upsert_attribute(list, attr) end)
    Lists.get_list(list.id)
  end

  defp upsert_attributes(list, _), do: list

  defp serialize(%List{} = l) do
    %{
      id: l.id,
      project_id: l.project_id,
      slug: l.slug,
      public_slug: l.public_slug,
      name: l.name,
      description: l.description,
      kind: l.kind,
      settings: l.settings,
      status: l.status,
      attributes: Enum.map(Lists.list_attributes(l.id), &serialize_attribute/1)
    }
  end

  defp serialize_attribute(%ListAttribute{} = a) do
    %{
      id: a.id,
      slug: a.slug,
      name: a.name,
      type: a.type,
      required: a.required,
      is_identity: a.is_identity,
      options: a.options,
      validation: a.validation,
      sort_order: a.sort_order,
      status: a.status
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

  # RFC-4180, UTF-8 w/ BOM, standard columns + one per declared attribute (D5).
  defp send_csv(conn, list, rows) do
    attr_slugs = Lists.list_attributes(list.id) |> Enum.map(& &1.slug)
    headers = ["email", "status", "source", "created_at"] ++ attr_slugs

    body =
      [csv_row(headers)] ++
        Enum.map(rows, fn s ->
          base = [s.email, s.status, s.source || "", to_string(s.inserted_at)]
          attrs = Enum.map(attr_slugs, fn slug -> csv_cell(Map.get(s.attribs || %{}, slug)) end)
          csv_row(base ++ attrs)
        end)

    # UTF-8 BOM (D5) so Excel reads it as UTF-8.
    csv = <<0xEF, 0xBB, 0xBF>> <> Enum.join(body, "\r\n") <> "\r\n"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{list.slug}-signups.csv"))
    |> send_resp(200, csv)
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

  defp not_found(conn), do: conn |> put_status(:not_found) |> json(%{error: "not found"})

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
