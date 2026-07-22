defmodule ForyouWeb.Management.ProjectsController do
  @moduledoc """
  Management CRUD for projects/services (API-key / system-level; no PBAC — this
  is the Terraform-provider surface). `create` accepts the project fields plus an
  optional `owner_user_id` that grants a project-level owner membership in the
  same transaction (mirrors `Management.OrganizationController`). Without an
  owner, the project is still visible to org members through org-role
  inheritance in `list_user_accessible_projects/2`, but per-project
  `check_user_permission` detail access requires a direct membership. `delete`
  archives (soft) rather than hard-deleting, matching `Management.ListsController`.
  Modeled on `Management.ListsController`.
  """
  use ForyouWeb, :controller

  import Ecto.Query

  alias Foryou.Projects
  alias Foryou.Schema.Projects.Project, as: Schema

  def index(conn, params) do
    query =
      case params["organization_id"] do
        nil -> Schema
        org_id -> from(p in Schema, where: p.organization_id == ^org_id)
      end

    projects = Foryou.Repo.all(query)
    json(conn, %{projects: Enum.map(projects, &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    case Projects.get_project(id) do
      nil -> not_found(conn)
      project -> json(conn, %{project: serialize(project)})
    end
  end

  def create(conn, %{"project" => params}) do
    attrs = Map.take(params, ~w(organization_id slug name description settings status))

    result =
      case params["owner_user_id"] do
        nil -> Projects.create_project(attrs)
        owner_id -> Projects.create_with_owner(attrs, owner_id)
      end

    case result do
      {:ok, project} ->
        conn |> put_status(:created) |> json(%{project: serialize(project)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def update(conn, %{"id" => id, "project" => params}) do
    attrs = Map.take(params, ~w(slug name description settings status))

    case Projects.update_project(id, attrs) do
      {:ok, project} -> json(conn, %{project: serialize(project)})
      {:error, :not_found} -> not_found(conn)
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  # Archive (soft) — safe deprovision for TF removal, matching mgmt lists.
  def delete(conn, %{"id" => id}) do
    case Projects.archive(id) do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, :not_found} -> not_found(conn)
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  # ── Helpers ────────────────────────────────────────────────────

  defp serialize(%Schema{} = p) do
    %{
      id: p.id,
      organization_id: p.organization_id,
      slug: p.slug,
      name: p.name,
      description: p.description,
      settings: p.settings,
      status: p.status,
      archived_at: p.archived_at
    }
  end

  defp not_found(conn), do: conn |> put_status(:not_found) |> json(%{error: "not found"})

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
