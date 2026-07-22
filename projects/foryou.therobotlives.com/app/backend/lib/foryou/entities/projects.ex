defmodule Foryou.Projects do
  alias Foryou.Projects.Project, as: Entity
  alias Foryou.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  import Ecto.Query

  # System/management create (Terraform provider) — no acting user, so no
  # per-user owner membership is granted. Org members still see the project via
  # org-role inheritance in `list_user_accessible_projects/2`. Pass an optional
  # owner to also grant a project-level membership (see `create_with_owner/3`).
  def create_project(attrs) do
    %Schema{} |> Schema.changeset(attrs) |> Foryou.Repo.insert()
  end

  def create_with_owner(attrs, user_id, context \\ Noizu.Context.system()) do
    Foryou.Repo.transaction(fn ->
      # `put_change/3` (not `Map.put`) so `created_by` is set regardless of
      # whether `attrs` is atom-keyed (authed ProjectController) or string-keyed
      # (Management.ProjectsController) — mixing key types raises Ecto.CastError.
      with {:ok, project} <-
             %Schema{}
             |> Schema.changeset(attrs)
             |> Ecto.Changeset.put_change(:created_by, user_id)
             |> Foryou.Repo.insert(),
           {:ok, _membership} <- Foryou.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> Foryou.Repo.rollback(reason)
      end
    end)
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    # Raw-SQL uuid params must be dumped to 16-byte binary (Postgrex uuid format);
    # passing the string raises DBConnection.EncodeError. Matches Foryou.Authz.
    params = [uuid_to_bin(user_id), uuid_to_bin(organization_id)]

    case Ecto.Adapters.SQL.query(Foryou.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() |> load_uuid_columns() end)
      _ -> []
    end
  end

  # Postgrex returns uuid columns as raw 16-byte binaries; load them back to
  # canonical strings so the response is JSON-encodable (Jason chokes on the raw
  # bytes). Converted by explicit column name — a blanket "16-byte binary" rule
  # would corrupt a 16-char slug/name, which are also binaries.
  @uuid_result_columns ~w(id organization_id)
  defp load_uuid_columns(map) do
    Enum.reduce(@uuid_result_columns, map, fn col, acc ->
      case Map.fetch(acc, col) do
        {:ok, bin} when is_binary(bin) -> Map.put(acc, col, load_uuid(bin))
        _ -> acc
      end
    end)
  end

  defp load_uuid(bin) do
    case Ecto.UUID.load(bin) do
      {:ok, uuid} -> uuid
      :error -> bin
    end
  end

  def get_project(id) do
    Foryou.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case Foryou.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> Foryou.Repo.update()
    end
  end

  def archive(id) do
    case Foryou.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> Foryou.Repo.update()
    end
  end

  def unarchive(id) do
    case Foryou.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> Foryou.Repo.update()
    end
  end

  def delete_project(id) do
    case Foryou.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> Foryou.Repo.update()
    end
  end

  def list_members(project_id) do
    Foryou.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end

  defp uuid_to_bin(nil), do: nil

  defp uuid_to_bin(uuid) when is_binary(uuid) do
    case Ecto.UUID.dump(uuid) do
      {:ok, bin} -> bin
      :error -> uuid
    end
  end
end
