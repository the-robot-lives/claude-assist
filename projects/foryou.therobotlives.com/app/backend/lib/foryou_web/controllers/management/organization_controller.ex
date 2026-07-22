defmodule ForyouWeb.Management.OrganizationController do
  @moduledoc """
  Management CRUD for organizations (API-key / system-level). Optional
  `owner_user_id` on create links an owner membership in the same transaction.
  Organizations have no soft-delete column, so delete is a hard delete (FK
  cascades apply); a blocked delete surfaces as 409.
  """
  use ForyouWeb, :controller

  alias Foryou.Schema.Organizations.Organization, as: OrgSchema
  alias Foryou.Organizations

  def index(conn, _params) do
    orgs = Foryou.Repo.all(OrgSchema)
    json(conn, %{organizations: Enum.map(orgs, &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    case Foryou.Repo.get(OrgSchema, id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      org -> json(conn, %{organization: serialize(org)})
    end
  end

  def create(conn, %{"organization" => params}) do
    attrs = Map.take(params, ["slug", "name", "settings"])

    result =
      case params["owner_user_id"] do
        nil -> %OrgSchema{} |> OrgSchema.changeset(attrs) |> Foryou.Repo.insert()
        owner_id -> Organizations.create_organization_with_owner(attrs, owner_id)
      end

    case result do
      {:ok, org} ->
        conn |> put_status(:created) |> json(%{organization: serialize(org)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def update(conn, %{"id" => id, "organization" => params}) do
    case Foryou.Repo.get(OrgSchema, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})

      org ->
        case org |> OrgSchema.changeset(Map.take(params, ["slug", "name", "settings"])) |> Foryou.Repo.update() do
          {:ok, updated} -> json(conn, %{organization: serialize(updated)})
          {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Foryou.Repo.get(OrgSchema, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})

      org ->
        case Foryou.Repo.delete(org) do
          {:ok, _} -> conn |> send_resp(:no_content, "")
          {:error, _cs} -> conn |> put_status(:conflict) |> json(%{error: "organization has dependent resources"})
        end
    end
  end

  defp serialize(%OrgSchema{} = o) do
    %{id: o.id, slug: o.slug, name: o.name, settings: o.settings}
  end

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
