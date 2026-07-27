defmodule Timely.Projects do
  alias Timely.Projects.Project, as: Entity
  alias Timely.Schema.Projects.Project, as: Schema

  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓃔𓏀𓆰𓍣⟧ create_with_owner :: auto-generated pointer for public function create_with_owner
  def create_with_owner(attrs, user_id, _context \\ Noizu.Context.system()) do
    Timely.Repo.transaction(fn ->
      with {:ok, project} <-
             %Schema{}
             |> Schema.changeset(Map.put(attrs, :created_by, user_id))
             |> Timely.Repo.insert(),
           {:ok, _membership} <-
             Timely.Authz.ScopedMemberships.add_member("project", project.id, user_id, "owner") do
        project
      else
        {:error, reason} -> Timely.Repo.rollback(reason)
      end
    end)
  end

  # ⟦𓇖𓋝𓀷𓍧⟧ list_for_user :: auto-generated pointer for public function list_for_user
  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(Timely.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

      _ ->
        []
    end
  end

  # ⟦𓐝𓈪𓀱𓁻⟧ get_project :: auto-generated pointer for public function get_project
  def get_project(id) do
    Timely.Repo.get(Schema, id)
  end

  # ⟦𓍝𓀍𓄕𓄡⟧ update_project :: auto-generated pointer for public function update_project
  def update_project(id, attrs) do
    case Timely.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> Timely.Repo.update()
    end
  end

  # ⟦𓊡𓈴𓅐𓇮⟧ archive :: auto-generated pointer for public function archive
  def archive(id) do
    case Timely.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> Timely.Repo.update()
    end
  end

  # ⟦𓄆𓎲𓏄𓅑⟧ unarchive :: auto-generated pointer for public function unarchive
  def unarchive(id) do
    case Timely.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> Timely.Repo.update()
    end
  end

  # ⟦𓏪𓌚𓍧𓀂⟧ delete_project :: auto-generated pointer for public function delete_project
  def delete_project(id) do
    case Timely.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> Timely.Repo.update()
    end
  end

  # ⟦𓐙𓈩𓆚𓁋⟧ list_members :: auto-generated pointer for public function list_members
  def list_members(project_id) do
    Timely.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
