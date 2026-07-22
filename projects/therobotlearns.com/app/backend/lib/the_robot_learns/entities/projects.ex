defmodule TheRobotLearns.Projects do
  alias TheRobotLearns.Projects.Project, as: Entity
  alias TheRobotLearns.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  def create_with_owner(attrs, user_id, _context \\ Noizu.Context.system()) do
    TheRobotLearns.Repo.transaction(fn ->
      with {:ok, project} <-
             %Schema{}
             |> Schema.changeset(Map.put(attrs, :created_by, user_id))
             |> TheRobotLearns.Repo.insert(),
           {:ok, _membership} <-
             TheRobotLearns.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> TheRobotLearns.Repo.rollback(reason)
      end
    end)
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(TheRobotLearns.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

      _ ->
        []
    end
  end

  def get_project(id) do
    TheRobotLearns.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case TheRobotLearns.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> TheRobotLearns.Repo.update()
    end
  end

  def archive(id) do
    case TheRobotLearns.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> TheRobotLearns.Repo.update()
    end
  end

  def unarchive(id) do
    case TheRobotLearns.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> TheRobotLearns.Repo.update()
    end
  end

  def delete_project(id) do
    case TheRobotLearns.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> TheRobotLearns.Repo.update()
    end
  end

  def list_members(project_id) do
    TheRobotLearns.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
