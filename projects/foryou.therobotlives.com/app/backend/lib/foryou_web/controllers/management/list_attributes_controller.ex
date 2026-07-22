defmodule ForyouWeb.Management.ListAttributesController do
  @moduledoc """
  Management CRUD for a list's typed attributes (API-key / system-level). Nested
  under `/lists/:id/attributes`. Idempotent create-by-slug so Terraform apply is
  stable. `delete` deprecates (soft) — stored values on historical signups are
  retained (US-034).
  """
  use ForyouWeb, :controller

  alias Foryou.Lists
  alias Foryou.Schema.Lists.ListAttribute

  def index(conn, %{"id" => list_id}) do
    case Lists.get_list(list_id) do
      nil -> not_found(conn)
      list -> json(conn, %{attributes: Enum.map(Lists.list_attributes(list.id), &serialize/1)})
    end
  end

  def create(conn, %{"id" => list_id, "attribute" => params}) do
    case Lists.get_list(list_id) do
      nil ->
        not_found(conn)

      list ->
        case Lists.upsert_attribute(list, params) do
          {:ok, attr} -> conn |> put_status(:created) |> json(%{attribute: serialize(attr)})
          {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  def update(conn, %{"id" => list_id, "attribute_id" => attr_id, "attribute" => params}) do
    with %{} = _list <- Lists.get_list(list_id),
         %ListAttribute{} = attr <- Lists.get_attribute(attr_id) do
      case Lists.update_attribute(attr, params) do
        {:ok, attr} -> json(conn, %{attribute: serialize(attr)})
        {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      _ -> not_found(conn)
    end
  end

  def delete(conn, %{"id" => list_id, "attribute_id" => attr_id}) do
    with %{} = _list <- Lists.get_list(list_id),
         %ListAttribute{} = attr <- Lists.get_attribute(attr_id) do
      case Lists.deprecate_attribute(attr) do
        {:ok, _} -> send_resp(conn, :no_content, "")
        {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      _ -> not_found(conn)
    end
  end

  defp serialize(%ListAttribute{} = a) do
    %{
      id: a.id,
      list_id: a.list_id,
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

  defp not_found(conn), do: conn |> put_status(:not_found) |> json(%{error: "not found"})

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
