defmodule Therobotplans.Projects do
  alias Therobotplans.Projects.Project, as: Entity
  alias Therobotplans.Schema.Projects.Project, as: Schema
  alias Therobotplans.Domains.Items.Queues

  use Noizu.Repo
  def_repo(entity: Entity)

  # Board methodology to materialize per project methodology. `custom` falls
  # through to the kanban default stage set (the escape hatch — user edits
  # stages afterward via the existing stage CRUD).
  defp board_methodology("custom"), do: "kanban"
  defp board_methodology(m) when m in ~w(kanban scrum waterfall spiral), do: m
  defp board_methodology(_), do: "kanban"

  def create_with_owner(attrs, user_id, _context \\ Noizu.Context.system()) do
    Therobotplans.Repo.transaction(fn ->
      with {:ok, project} <-
             %Schema{}
             |> Schema.changeset(Map.put(attrs, :created_by, user_id))
             |> Therobotplans.Repo.insert(),
           {:ok, _membership} <-
             Therobotplans.Authz.ScopedMemberships.add_member(
               "project",
               project.id,
               user_id,
               "owner"
             ) do
        project
      else
        {:error, reason} -> Therobotplans.Repo.rollback(reason)
      end
    end)
  end

  @typedoc "kanban | scrum | waterfall | spiral | custom"
  @type methodology :: String.t()

  @doc """
  Create a project with an owner AND provision its default board (methodology
  stage set + a Scrum "Sprint 1" iteration) atomically. Either both the project
  and its linked board exist, or neither does — the whole unit is one
  transaction. `Queues.create/1` opens its own transaction, which nests here as
  a savepoint, so a board-seed failure rolls back the project too.

  Returns `{:ok, %{project: project, board: board}}` with `default_queue_id`
  set, or `{:error, changeset | reason}`.
  """
  @spec create_with_methodology(map(), methodology(), Ecto.UUID.t(), Noizu.Context.t()) ::
          {:ok, %{project: Schema.t(), board: term()}} | {:error, term()}
  def create_with_methodology(attrs, methodology, user_id, _context \\ Noizu.Context.system()) do
    methodology = normalize_methodology(methodology)

    attrs =
      attrs
      |> Map.put(:default_methodology, methodology)
      |> maybe_derive_key_prefix()
      |> Map.put(:created_by, user_id)

    Therobotplans.Repo.transaction(fn ->
      with {:ok, project} <-
             %Schema{} |> Schema.changeset(attrs) |> Therobotplans.Repo.insert(),
           {:ok, _membership} <-
             Therobotplans.Authz.ScopedMemberships.add_member(
               "project",
               project.id,
               user_id,
               "owner"
             ),
           {:ok, board} <- provision_board(project, methodology, "board"),
           {:ok, project} <- repoint(project, board.id) do
        %{project: project, board: Queues.get_board(board.id)}
      else
        {:error, reason} -> Therobotplans.Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Idempotently provision (or re-provision) a project's default board for a
  methodology.

    * Never provisioned (`default_queue_id` nil) → provision fresh at slug
      `"board"`, repoint, `migration_required: false`.
    * Already on `methodology` → no-op, returns the existing board unchanged.
    * Different methodology → provisions a NEW board (slug `"board-<methodology>"`),
      repoints `default_queue_id`, leaves the old board intact, and returns
      `migration_required: true` with a best-effort `stage_map` hint
      (old.slug → new.slug by slug then kind). Item re-mapping is deferred
      (US-022-adjacent) — this only repoints the default board.

  Returns `{:ok, %{board: board, migration_required: boolean(), stage_map: map()}}`
  or `{:error, :not_found | term()}`.
  """
  @spec provision(Schema.t() | Ecto.UUID.t(), methodology(), keyword()) ::
          {:ok, %{board: term(), migration_required: boolean(), stage_map: map()}}
          | {:error, term()}
  def provision(project_or_id, methodology, opts \\ [])

  def provision(%Schema{} = project, methodology, opts),
    do: do_provision(project, normalize_methodology(methodology), opts)

  def provision(id, methodology, opts) when is_binary(id) do
    case get_project(id) do
      nil -> {:error, :not_found}
      project -> do_provision(project, normalize_methodology(methodology), opts)
    end
  end

  defp do_provision(%Schema{default_queue_id: nil} = project, methodology, _opts) do
    Therobotplans.Repo.transaction(fn ->
      with {:ok, board} <- provision_board(project, methodology, "board"),
           {:ok, _project} <- repoint(project, board.id) do
        %{board: Queues.get_board(board.id), migration_required: false, stage_map: %{}}
      else
        {:error, reason} -> Therobotplans.Repo.rollback(reason)
      end
    end)
  end

  defp do_provision(%Schema{default_methodology: methodology} = project, methodology, _opts) do
    # Idempotent no-op: requested methodology already matches. No writes.
    {:ok,
     %{board: Queues.get_board(project.default_queue_id), migration_required: false, stage_map: %{}}}
  end

  defp do_provision(%Schema{} = project, methodology, _opts) do
    old_board = Queues.get_board(project.default_queue_id)

    Therobotplans.Repo.transaction(fn ->
      with {:ok, board} <- provision_board(project, methodology, "board-#{methodology}"),
           {:ok, project} <- repoint(project, board.id) do
        new_board = Queues.get_board(board.id)

        %{
          board: new_board,
          migration_required: true,
          stage_map: build_stage_map(old_board, new_board),
          project: project
        }
        |> Map.take([:board, :migration_required, :stage_map])
      else
        {:error, reason} -> Therobotplans.Repo.rollback(reason)
      end
    end)
  end

  # Seed a board (stages via Queues.create/1) plus, for scrum, one active
  # "Sprint 1" iteration. Runs inside the caller's transaction.
  defp provision_board(project, methodology, slug) do
    board_attrs = %{
      organization_id: project.organization_id,
      project_id: project.id,
      name: "#{project.name} Board",
      slug: slug,
      methodology: board_methodology(methodology)
    }

    with {:ok, board} <- Queues.create(board_attrs),
         :ok <- maybe_seed_scrum_iteration(board, methodology) do
      {:ok, board}
    end
  end

  defp maybe_seed_scrum_iteration(board, "scrum") do
    case Queues.add_iteration(%{
           queue_id: board.id,
           name: "Sprint 1",
           sequence: 0,
           status: "active"
         }) do
      {:ok, _iteration} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_seed_scrum_iteration(_board, _methodology), do: :ok

  defp repoint(project, board_id) do
    project |> Schema.changeset(%{default_queue_id: board_id}) |> Therobotplans.Repo.update()
  end

  # Best-effort old→new stage mapping hint for the deferred item-migration UI.
  defp build_stage_map(nil, _new_board), do: %{}

  defp build_stage_map(old_board, new_board) do
    new_by_slug = Map.new(new_board.stages, &{&1.slug, &1.slug})
    new_by_kind = Map.new(new_board.stages, &{&1.kind, &1.slug})

    Map.new(old_board.stages, fn stage ->
      {stage.slug, Map.get(new_by_slug, stage.slug) || Map.get(new_by_kind, stage.kind)}
    end)
  end

  @doc """
  A compact JSON-ready ref for a project's provisioned default board, or nil.
  `%{id, slug, methodology, stage_count}`.
  """
  def default_queue_ref(nil), do: nil

  def default_queue_ref(queue_id) do
    case Queues.get_board(queue_id) do
      nil -> nil
      board -> board_ref(board)
    end
  end

  @doc "Shape a board struct into the compact ref used in API responses."
  def board_ref(nil), do: nil

  def board_ref(board) do
    %{
      id: board.id,
      slug: board.slug,
      methodology: board.methodology,
      stage_count: length(board.stages || [])
    }
  end

  defp normalize_methodology(nil), do: "kanban"
  defp normalize_methodology(""), do: "kanban"
  defp normalize_methodology(m) when is_binary(m), do: String.downcase(m)
  defp normalize_methodology(_), do: "kanban"

  # Derive a key_prefix from the slug when the caller didn't supply one. Only set
  # it if the derived value satisfies the schema's 2–16 uppercase-alnum rule;
  # otherwise leave nil (the column is nullable).
  defp maybe_derive_key_prefix(attrs) do
    case fetch_attr(attrs, :key_prefix) do
      value when is_binary(value) and value != "" ->
        attrs

      _ ->
        derived =
          (fetch_attr(attrs, :slug) || "")
          |> String.upcase()
          |> String.replace(~r/[^A-Z0-9]/, "")
          |> String.slice(0, 8)

        if String.length(derived) >= 2 do
          put_attr(attrs, :key_prefix, derived)
        else
          attrs
        end
    end
  end

  defp fetch_attr(attrs, key) when is_atom(key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp put_attr(attrs, key, value) do
    cond do
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.put(attrs, Atom.to_string(key), value)
      true -> Map.put(attrs, key, value)
    end
  end

  def list_for_user(user_id, organization_id \\ nil) do
    sql = "SELECT * FROM list_user_accessible_projects($1::uuid, $2::uuid)"
    params = [user_id, organization_id]

    case Ecto.Adapters.SQL.query(Therobotplans.Repo, sql, params) do
      {:ok, %{rows: rows, columns: cols}} ->
        Enum.map(rows, fn row -> Enum.zip(cols, row) |> Map.new() end)

      _ ->
        []
    end
  end

  def get_project(id) do
    Therobotplans.Repo.get(Schema, id)
  end

  def update_project(id, attrs) do
    case Therobotplans.Repo.get(Schema, id) do
      nil -> {:error, :not_found}
      project -> project |> Schema.changeset(attrs) |> Therobotplans.Repo.update()
    end
  end

  def archive(id) do
    case Therobotplans.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "archived", archived_at: DateTime.utc_now()})
        |> Therobotplans.Repo.update()
    end
  end

  def unarchive(id) do
    case Therobotplans.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "active", archived_at: nil})
        |> Therobotplans.Repo.update()
    end
  end

  def delete_project(id) do
    case Therobotplans.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      project ->
        project
        |> Schema.changeset(%{status: "deleted"})
        |> Therobotplans.Repo.update()
    end
  end

  def list_members(project_id) do
    Therobotplans.Authz.ScopedMemberships.list_for_resource("project", project_id)
  end
end
