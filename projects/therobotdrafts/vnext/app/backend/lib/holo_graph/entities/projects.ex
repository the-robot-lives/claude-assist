defmodule HoloGraph.Projects do
  alias HoloGraph.Projects.Project, as: Entity
  alias HoloGraph.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  def create_with_owner(attrs, user_id, _context \\ Noizu.Context.system()) do
    HoloGraph.Repo.transaction(fn ->
      with {:ok, project} <-
             %Schema{}
             |> Schema.changeset(Map.put(attrs, :created_by, user_id))
             |> HoloGraph.Repo.insert(),
           {:ok, _membership} <-
             HoloGraph.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> HoloGraph.Repo.rollback(reason)
      end
    end)
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(HoloGraph.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

      _ ->
        []
    end
  end

  def get_project(id) do
    HoloGraph.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case HoloGraph.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> HoloGraph.Repo.update()
    end
  end

  def archive(id) do
    case HoloGraph.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> HoloGraph.Repo.update()
    end
  end

  def unarchive(id) do
    case HoloGraph.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> HoloGraph.Repo.update()
    end
  end

  def delete_project(id) do
    case HoloGraph.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> HoloGraph.Repo.update()
    end
  end

  def list_members(project_id) do
    HoloGraph.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
