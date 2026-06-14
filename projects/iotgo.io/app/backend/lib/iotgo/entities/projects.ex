defmodule Iotgo.Projects do
  alias Iotgo.Projects.Project, as: Entity
  alias Iotgo.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  import Ecto.Query

  def create_with_owner(attrs, user_id, context \\ Noizu.Context.system()) do
    Iotgo.Repo.transaction(fn ->
      with {:ok, project} <- %Schema{} |> Schema.changeset(Map.put(attrs, :created_by, user_id)) |> Iotgo.Repo.insert(),
           {:ok, _membership} <- Iotgo.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> Iotgo.Repo.rollback(reason)
      end
    end)
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(Iotgo.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)
      _ -> []
    end
  end

  def get_project(id) do
    Iotgo.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case Iotgo.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> Iotgo.Repo.update()
    end
  end

  def archive(id) do
    case Iotgo.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> Iotgo.Repo.update()
    end
  end

  def unarchive(id) do
    case Iotgo.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> Iotgo.Repo.update()
    end
  end

  def delete_project(id) do
    case Iotgo.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> Iotgo.Repo.update()
    end
  end

  def list_members(project_id) do
    Iotgo.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
