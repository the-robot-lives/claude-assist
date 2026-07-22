defmodule TherobotknowsWeb.AISettingsController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.AI.Budget

  def show(conn, _params) do
    user_id = user_id(conn)
    json(conn, %{ai: Budget.usage_summary(user_id)})
  end

  def update(conn, %{"ai" => attrs}) do
    user_id = user_id(conn)

    case Budget.update_prefs(user_id, attrs) do
      {:ok, _} -> json(conn, %{ai: Budget.usage_summary(user_id)})
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(cs)})
    end
  end

  def update(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "ai params required"})
  end

  defp user_id(conn) do
    case Therobotknows.Guardian.Plug.current_resource(conn) do
      %Therobotknows.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotknows.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end
end
