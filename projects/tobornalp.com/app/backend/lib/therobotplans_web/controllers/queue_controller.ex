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
