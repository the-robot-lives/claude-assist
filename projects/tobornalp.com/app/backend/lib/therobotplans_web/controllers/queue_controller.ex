defmodule TherobotplansWeb.QueueController do
  @moduledoc """
  REST surface for boards (queues) and their stages/iterations. Mirrors the
  Items.Queues context for human/frontend use.
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Items.Queues
  alias Therobotplans.Schema.ItemQueue
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/queues[?project_id=]
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      project_id = blank_to_nil(params["project_id"])
      boards = Queues.list(org_id, project_id)

      json(conn, %{
        queues: Enum.map(boards, &queue_summary/1),
        methodologies: ItemQueue.methodologies()
      })
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/queues
  def create(conn, %{"org_id" => org_id, "queue" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs = %{
        name: params["name"],
        slug: params["slug"],
        description: params["description"],
        methodology: params["methodology"] || "kanban",
        organization_id: org_id,
        project_id: blank_to_nil(params["project_id"])
      }

      case Queues.create(attrs) do
        {:ok, board} ->
          conn |> put_status(:created) |> json(%{queue: queue_detail(board)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/queues/:id
  def show(conn, %{"org_id" => org_id, "id" => id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer"),
         %{organization_id: ^org_id} = board when not is_nil(board) <- Queues.get_by_id(id) do
      json(conn, %{queue: queue_detail(board)})
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Queue not found"})
      err -> handle_error(conn, err)
    end
  end

  def update(conn, %{"org_id" => org_id, "id" => id, "queue" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      case Queues.update_board(id, params) do
        {:ok, board} ->
          json(conn, %{queue: queue_detail(board)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Queue not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # DELETE /api/v1/organizations/:org_id/queues/:id
  def delete(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_queue(conn, org_id, id, "member", fn _board ->
      case Queues.delete_board(id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Queue not found"})
      end
    end)
  end

  # ── Stages ───────────────────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/queues/:queue_id/stages
  def stages(conn, %{"org_id" => org_id, "queue_id" => queue_id}) do
    with_org_queue(conn, org_id, queue_id, "viewer", fn board ->
      json(conn, %{stages: Enum.map(Queues.list_stages(board.id), &stage_to_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/queues/:queue_id/stages
  def create_stage(conn, %{"org_id" => org_id, "queue_id" => queue_id, "stage" => params}) do
    with_org_queue(conn, org_id, queue_id, "member", fn board ->
      attrs = %{
        queue_id: board.id,
        slug: params["slug"],
        name: params["name"],
        kind: params["kind"] || "stage",
        position: params["position"],
        wip_limit: params["wip_limit"],
        config: params["config"] || %{}
      }

      case Queues.add_stage(attrs) do
        {:ok, stage} ->
          conn |> put_status(:created) |> json(%{stage: stage_to_json(stage)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # PUT /api/v1/organizations/:org_id/queues/:queue_id/stages/:id
  def update_stage(conn, %{"org_id" => org_id, "queue_id" => queue_id, "id" => stage_id, "stage" => params}) do
    with_org_stage(conn, org_id, queue_id, stage_id, "member", fn stage ->
      case Queues.update_stage(stage.id, params) do
        {:ok, updated} ->
          json(conn, %{stage: stage_to_json(updated)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Stage not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/queues/:queue_id/stages/:id
  def delete_stage(conn, %{"org_id" => org_id, "queue_id" => queue_id, "id" => stage_id}) do
    with_org_stage(conn, org_id, queue_id, stage_id, "member", fn stage ->
      case Queues.delete_stage(stage.id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Stage not found"})
      end
    end)
  end

  # ── Iterations (sprints / cycles) ─────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/queues/:queue_id/iterations
  def iterations(conn, %{"org_id" => org_id, "queue_id" => queue_id}) do
    with_org_queue(conn, org_id, queue_id, "viewer", fn board ->
      json(conn, %{iterations: Enum.map(Queues.list_iterations(board.id), &iteration_to_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/queues/:queue_id/iterations
  def create_iteration(conn, %{"org_id" => org_id, "queue_id" => queue_id, "iteration" => params}) do
    with_org_queue(conn, org_id, queue_id, "member", fn board ->
      attrs = %{
        queue_id: board.id,
        name: params["name"],
        sequence: params["sequence"],
        status: params["status"] || "planned",
        goal: params["goal"],
        starts_on: params["starts_on"],
        ends_on: params["ends_on"],
        config: params["config"] || %{}
      }

      case Queues.add_iteration(attrs) do
        {:ok, iteration} ->
          conn |> put_status(:created) |> json(%{iteration: iteration_to_json(iteration)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # PUT /api/v1/organizations/:org_id/queues/:queue_id/iterations/:id
  def update_iteration(conn, %{"org_id" => org_id, "queue_id" => queue_id, "id" => iteration_id, "iteration" => params}) do
    with_org_iteration(conn, org_id, queue_id, iteration_id, "member", fn iteration ->
      case Queues.update_iteration(iteration.id, params) do
        {:ok, updated} ->
          json(conn, %{iteration: iteration_to_json(updated)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Iteration not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/queues/:queue_id/iterations/:id
  def delete_iteration(conn, %{"org_id" => org_id, "queue_id" => queue_id, "id" => iteration_id}) do
    with_org_iteration(conn, org_id, queue_id, iteration_id, "member", fn iteration ->
      case Queues.delete_iteration(iteration.id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Iteration not found"})
      end
    end)
  end

  defp queue_summary(q) do
    %{
      id: q.id,
      name: q.name,
      slug: q.slug,
      methodology: q.methodology,
      organization_id: q.organization_id,
      project_id: q.project_id
    }
  end

  defp queue_detail(q) do
    Map.merge(queue_summary(q), %{
      description: q.description,
      config: q.config,
      stages:
        Enum.map(q.stages || [], fn s ->
          %{
            id: s.id,
            slug: s.slug,
            name: s.name,
            kind: s.kind,
            position: s.position,
            wip_limit: s.wip_limit
          }
        end),
      iterations:
        Enum.map(q.iterations || [], fn i ->
          %{
            id: i.id,
            name: i.name,
            sequence: i.sequence,
            status: i.status,
            starts_on: i.starts_on,
            ends_on: i.ends_on
          }
        end)
    })
  end

  # Resolve org, authorize, load the board, ensure it belongs to the org.
  # Mirrors QueueController.show — a board is only editable through its own org
  # scope (tri-scoped global boards are readable via list, not mutated per-org).
  defp with_org_queue(conn, org_id, queue_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         board when not is_nil(board) <- Queues.get_by_id(queue_id),
         true <- board.organization_id == org_id do
      fun.(board)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Queue not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Queue not found"})
      err -> handle_error(conn, err)
    end
  end

  # A stage is org-scoped through its queue; also verify it belongs to the
  # route's queue_id (blocks moving a stage across boards via the URL).
  defp with_org_stage(conn, org_id, queue_id, stage_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         stage when not is_nil(stage) <- Queues.get_stage(stage_id),
         true <- stage.queue_id == queue_id,
         board when not is_nil(board) <- Queues.get_by_id(queue_id),
         true <- board.organization_id == org_id do
      fun.(stage)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Stage not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Stage not found"})
      err -> handle_error(conn, err)
    end
  end

  # An iteration is org-scoped through its queue (same chain as a stage).
  defp with_org_iteration(conn, org_id, queue_id, iteration_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         iteration when not is_nil(iteration) <- Queues.get_iteration(iteration_id),
         true <- iteration.queue_id == queue_id,
         board when not is_nil(board) <- Queues.get_by_id(queue_id),
         true <- board.organization_id == org_id do
      fun.(iteration)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Iteration not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Iteration not found"})
      err -> handle_error(conn, err)
    end
  end

  defp stage_to_json(s) do
    %{
      id: s.id,
      queue_id: s.queue_id,
      slug: s.slug,
      name: s.name,
      kind: s.kind,
      position: s.position,
      wip_limit: s.wip_limit,
      config: s.config
    }
  end

  defp iteration_to_json(i) do
    %{
      id: i.id,
      queue_id: i.queue_id,
      name: i.name,
      sequence: i.sequence,
      status: i.status,
      goal: i.goal,
      starts_on: i.starts_on,
      ends_on: i.ends_on,
      config: i.config
    }
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Organization not found"})

      {:error, :not_a_member} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp get_user_id(conn) do
    case Therobotplans.Guardian.Plug.current_resource(conn) do
      %Therobotplans.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotplans.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
