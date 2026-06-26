defmodule Therobotsdayjob.Projects do
  alias Therobotsdayjob.Projects.Project, as: Entity
  alias Therobotsdayjob.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  import Ecto.Query

  def create_with_owner(attrs, user_id, context \\ Noizu.Context.system()) do
    Therobotsdayjob.Repo.transaction(fn ->
      with {:ok, project} <- %Schema{} |> Schema.changeset(Map.put(attrs, :created_by, user_id)) |> Therobotsdayjob.Repo.insert(),
           {:ok, _membership} <- Therobotsdayjob.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> Therobotsdayjob.Repo.rollback(reason)
      end
    end)
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(Therobotsdayjob.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)
      _ -> []
    end
  end

  def get_project(id) do
    Therobotsdayjob.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case Therobotsdayjob.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> Therobotsdayjob.Repo.update()
    end
  end

  def archive(id) do
    case Therobotsdayjob.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> Therobotsdayjob.Repo.update()
    end
  end

  def unarchive(id) do
    case Therobotsdayjob.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> Therobotsdayjob.Repo.update()
    end
  end

  def delete_project(id) do
    case Therobotsdayjob.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> Therobotsdayjob.Repo.update()
    end
  end

  def list_members(project_id) do
    Therobotsdayjob.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
