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

  @uuid_columns ~w(id organization_id created_by)

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"

    # Raw queries need uuid params dumped to 16-byte binaries, and uuid columns
    # in the result loaded back to strings or Jason chokes on the raw binaries.
    with {:ok, user_param} <- Ecto.UUID.dump(user_id),
         {:ok, org_param} <- dump_optional_uuid(organization_id),
         {:ok, %{rows: rows, columns: cols}} <-
           Ecto.Adapters.SQL.query(TheRobotLearns.Repo, sql, [user_param, org_param]) do
      Enum.map(rows, fn row ->
        Enum.zip(cols, row)
        |> Map.new(fn
          {col, val} when col in @uuid_columns -> {col, load_uuid(val)}
          {col, val} -> {col, val}
        end)
      end)
    else
      _ -> []
    end
  end

  defp dump_optional_uuid(nil), do: {:ok, nil}
  defp dump_optional_uuid(uuid), do: Ecto.UUID.dump(uuid)

  defp load_uuid(<<_::128>> = bin) do
    case Ecto.UUID.load(bin) do
      {:ok, uuid} -> uuid
      :error -> bin
    end
  end

  defp load_uuid(other), do: other

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
