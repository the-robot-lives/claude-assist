defmodule TherobotknowsWeb.SessionController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Sessions

  def index(conn, %{"universe_id" => universe_id}) do
    user_id = user_id(conn)

    case Sessions.list(universe_id, user_id) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def create(conn, %{"universe_id" => universe_id, "session" => attrs}) do
    user_id = user_id(conn)

    case Sessions.create(universe_id, attrs, user_id) do
      {:ok, session} -> conn |> put_status(:created) |> json(%{session: session})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(cs.errors)})
    end
  end

  def show(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Sessions.get(universe_id, id, user_id) do
      {:ok, session} -> json(conn, %{session: session})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def add_log(conn, %{"universe_id" => universe_id, "id" => id, "body" => body}) do
    user_id = user_id(conn)

    case Sessions.add_log(universe_id, id, body, user_id) do
      {:ok, log} -> conn |> put_status(:created) |> json(%{log_entry: log})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def close(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Sessions.close(universe_id, id, user_id) do
      {:ok, session} -> json(conn, %{session: session})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
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
