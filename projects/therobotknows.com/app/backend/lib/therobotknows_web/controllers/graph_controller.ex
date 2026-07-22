defmodule TherobotknowsWeb.GraphController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Graph

  def show(conn, %{"universe_id" => universe_id} = params) do
    user_id = user_id(conn)

    opts = [
      type: params["type"],
      status: params["status"],
      tag: params["tag"],
      era: params["era"],
      region: params["region"]
    ]

    case Graph.graph(universe_id, user_id, opts) do
      {:ok, payload} -> json(conn, payload)
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
