defmodule TheRobotLearnsWeb.LearningController do
  @moduledoc """
  Generic project-scoped learning-content API. `:content_type` in the path
  selects the type (see TheRobotLearns.Learning). This is also the push/ingest
  surface the CLI/MCP connector uses to publish content into a project.
  """
  use TheRobotLearnsWeb, :controller

  alias TheRobotLearns.Authz
  alias TheRobotLearns.Learning

  def index(conn, %{"project_id" => project_id, "content_type" => type} = params) do
    with :ok <- authorize(conn, project_id, "project:view"),
         {:ok, records} <- Learning.list(type, project_id, params["parent_id"]) do
      json(conn, %{items: records})
    else
      error -> handle_error(conn, error)
    end
  end

  def create(conn, %{"project_id" => project_id, "content_type" => type, "item" => attrs}) do
    with :ok <- authorize(conn, project_id, "project:update"),
         {:ok, record} <- Learning.create(type, project_id, attrs, get_user_id(conn)) do
      conn |> put_status(:created) |> json(%{item: record})
    else
      error -> handle_error(conn, error)
    end
  end

  def create(conn, _params),
    do: conn |> put_status(:bad_request) |> json(%{error: "item params required"})

  def update(conn, %{"project_id" => project_id, "content_type" => type, "id" => id, "item" => attrs}) do
    with :ok <- authorize(conn, project_id, "project:update"),
         {:ok, record} <- Learning.update(type, project_id, id, attrs) do
      json(conn, %{item: record})
    else
      error -> handle_error(conn, error)
    end
  end

  def update(conn, _params),
    do: conn |> put_status(:bad_request) |> json(%{error: "item params required"})

  def delete(conn, %{"project_id" => project_id, "content_type" => type, "id" => id}) do
    with :ok <- authorize(conn, project_id, "project:update"),
         {:ok, _record} <- Learning.delete(type, project_id, id) do
      json(conn, %{ok: true})
    else
      error -> handle_error(conn, error)
    end
  end

  # ── helpers ───────────────────────────────────────────────────────────

  defp authorize(conn, project_id, permission) do
    if Authz.check_permission(get_user_id(conn), "project", project_id, permission) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp handle_error(conn, :error),
    do: conn |> put_status(:not_found) |> json(%{error: "Unknown content type"})

  defp handle_error(conn, {:error, :forbidden}),
    do: conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})

  defp handle_error(conn, {:error, :not_found}),
    do: conn |> put_status(:not_found) |> json(%{error: "Not found"})

  defp handle_error(conn, {:error, :parent_required}),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: "parent_id required for this content type"})

  defp handle_error(conn, {:error, :parent_not_found}),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Parent record not found"})

  defp handle_error(conn, {:error, :parent_not_in_project}),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Parent record belongs to another project"})

  defp handle_error(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end

  defp handle_error(conn, _),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Unable to process request"})

  defp get_user_id(conn) do
    case TheRobotLearns.Guardian.Plug.current_resource(conn) do
      %TheRobotLearns.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %TheRobotLearns.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end
end
