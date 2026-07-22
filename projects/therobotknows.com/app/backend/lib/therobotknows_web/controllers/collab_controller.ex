defmodule TherobotknowsWeb.CollabController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Collab

  def invites(conn, %{"universe_id" => universe_id}) do
    user_id = user_id(conn)

    case Collab.list_invites(universe_id, user_id) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def invite(conn, %{"universe_id" => universe_id, "email" => email} = params) do
    user_id = user_id(conn)
    role = params["role"] || "editor"

    case Collab.invite(universe_id, email, role, user_id) do
      {:ok, inv} -> conn |> put_status(:created) |> json(%{invite: inv})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(cs.errors)})
    end
  end

  def accept(conn, %{"token" => token}) do
    user = current_user(conn)

    case Collab.accept(token, user.id, user.email) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Invite not found"})
      {:error, :email_mismatch} -> conn |> put_status(:forbidden) |> json(%{error: "Invite email mismatch"})
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def public(conn, %{"universe_id" => universe_id, "public_read" => public_read}) do
    user_id = user_id(conn)

    case Collab.set_public(universe_id, public_read, user_id) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
      {:error, err} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(err)})
    end
  end

  defp user_id(conn) do
    case Therobotknows.Guardian.Plug.current_resource(conn) do
      %Therobotknows.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotknows.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp current_user(conn) do
    session = Therobotknows.Guardian.Plug.current_resource(conn)

    id =
      case session.user do
        {:ref, _, id} -> id
        %{id: id} -> id
      end

    {:ok, user} = Therobotknows.Users.get_user(id, Noizu.Context.system())
    user
  end
end
