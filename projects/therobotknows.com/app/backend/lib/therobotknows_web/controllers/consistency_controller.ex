defmodule TherobotknowsWeb.ConsistencyController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Consistency

  def index(conn, %{"universe_id" => universe_id} = params) do
    user_id = user_id(conn)

    case Consistency.list_issues(universe_id, user_id, status: params["status"] || "open") do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def show(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Consistency.get_issue(universe_id, id, user_id) do
      {:ok, issue} -> json(conn, %{issue: issue})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def resolve(conn, %{"universe_id" => universe_id, "id" => id} = params) do
    user_id = user_id(conn)
    resolution = params["resolution"] || %{"status" => params["status"] || "resolved"}

    case Consistency.resolve(universe_id, id, resolution, user_id) do
      {:ok, issue} -> json(conn, %{issue: issue})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(cs.errors)})
    end
  end

  def run(conn, %{"universe_id" => universe_id}) do
    user_id = user_id(conn)

    case Consistency.run_checks(universe_id, user_id) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  defp user_id(conn) do
    case Therobotknows.Guardian.Plug.current_resource(conn) do
      %Therobotknows.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotknows.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end
end
