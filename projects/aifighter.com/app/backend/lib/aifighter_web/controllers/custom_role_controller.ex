defmodule AifighterWeb.CustomRoleController do
  use AifighterWeb, :controller

  alias Aifighter.Schema.Organizations.CustomRole, as: RoleSchema
  alias Aifighter.Schema.Organizations.CustomRolePermission, as: PermSchema
  alias Aifighter.Authz

  import Ecto.Query

  def index(conn, %{"org_id" => org_id}) do
    user_id = get_user_id(conn)

    case Authz.authorize(user_id, "organization", org_id, "viewer") do
      {:ok, _} ->
        roles = Aifighter.Repo.all(from r in RoleSchema, where: r.organization_id == ^org_id and r.is_active == true)
        json(conn, %{roles: Enum.map(roles, &role_to_json/1)})
      {:error, _} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def create(conn, %{"org_id" => org_id, "role" => role_params}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "organization", org_id, "organization:manage_settings") do
      attrs = Map.put(role_params, "organization_id", org_id)

      case %RoleSchema{} |> RoleSchema.changeset(attrs) |> Aifighter.Repo.insert() do
        {:ok, role} -> conn |> put_status(:created) |> json(%{role: role_to_json(role)})
        {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def show(conn, %{"org_id" => org_id, "id" => role_id}) do
    user_id = get_user_id(conn)

    case Authz.authorize(user_id, "organization", org_id, "viewer") do
      {:ok, _} ->
        case Aifighter.Repo.one(from r in RoleSchema, where: r.id == ^role_id and r.organization_id == ^org_id) do
          nil -> conn |> put_status(:not_found) |> json(%{error: "Role not found"})
          role ->
            permissions = Aifighter.Repo.all(from p in PermSchema, where: p.role_id == ^role_id, select: p.permission)
            json(conn, %{role: Map.put(role_to_json(role), :permissions, permissions)})
        end
      {:error, _} ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def update(conn, %{"org_id" => org_id, "id" => role_id, "role" => role_params}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "organization", org_id, "organization:manage_settings") do
      case Aifighter.Repo.one(from r in RoleSchema, where: r.id == ^role_id and r.organization_id == ^org_id) do
        nil -> conn |> put_status(:not_found) |> json(%{error: "Role not found"})
        role ->
          case role |> RoleSchema.changeset(role_params) |> Aifighter.Repo.update() do
            {:ok, updated} -> json(conn, %{role: role_to_json(updated)})
            {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
          end
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def delete(conn, %{"org_id" => org_id, "id" => role_id}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "organization", org_id, "organization:manage_settings") do
      case Aifighter.Repo.one(from r in RoleSchema, where: r.id == ^role_id and r.organization_id == ^org_id) do
        nil -> conn |> put_status(:not_found) |> json(%{error: "Role not found"})
        role ->
          case role |> Ecto.Changeset.change(is_active: false) |> Aifighter.Repo.update() do
            {:ok, _} -> json(conn, %{message: "Role deactivated"})
            {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "Failed to deactivate role"})
          end
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def add_permission(conn, %{"org_id" => org_id, "role_id" => role_id, "permission" => permission}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "organization", org_id, "organization:manage_settings") do
      case %PermSchema{} |> PermSchema.changeset(%{role_id: role_id, permission: permission}) |> Aifighter.Repo.insert() do
        {:ok, _} ->
          permissions = Aifighter.Repo.all(from p in PermSchema, where: p.role_id == ^role_id, select: p.permission)
          conn |> put_status(:created) |> json(%{permissions: permissions})
        {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  def remove_permission(conn, %{"org_id" => org_id, "role_id" => role_id, "permission_id" => perm_id}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "organization", org_id, "organization:manage_settings") do
      case Aifighter.Repo.one(from p in PermSchema, where: p.id == ^perm_id and p.role_id == ^role_id) do
        nil -> conn |> put_status(:not_found) |> json(%{error: "Permission not found"})
        perm ->
          {:ok, _} = Aifighter.Repo.delete(perm)
          json(conn, %{message: "Permission removed"})
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp get_user_id(conn) do
    case Aifighter.Guardian.Plug.current_resource(conn) do
      %Aifighter.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Aifighter.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp role_to_json(role) do
    %{
      id: role.id,
      organization_id: role.organization_id,
      name: role.name,
      display_name: role.display_name,
      description: role.description,
      is_active: role.is_active
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
