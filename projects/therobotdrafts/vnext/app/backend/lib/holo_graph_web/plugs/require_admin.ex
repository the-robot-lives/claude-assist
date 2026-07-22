defmodule HoloGraphWeb.Plugs.RequireAdmin do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_user(conn) do
      {:ok, user} ->
        if Map.get(user, :admin, false) do
          assign(conn, :admin_user, user)
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "Admin access required"}))
          |> halt()
        end

      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Authentication required"}))
        |> halt()
    end
  end

  defp get_user(conn) do
    case HoloGraph.Guardian.Plug.current_resource(conn) do
      %HoloGraph.Users.Sessions.UserSession{user: {:ref, _, id}} ->
        case HoloGraph.Repo.get(HoloGraph.Schema.Users.User, id) do
          nil -> :error
          user -> {:ok, user}
        end

      %HoloGraph.Users.Sessions.UserSession{user: %{id: id}} ->
        case HoloGraph.Repo.get(HoloGraph.Schema.Users.User, id) do
          nil -> :error
          user -> {:ok, user}
        end

      _ ->
        :error
    end
  end
end
