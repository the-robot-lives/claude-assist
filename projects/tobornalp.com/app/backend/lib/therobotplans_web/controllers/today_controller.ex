defmodule TherobotplansWeb.TodayController do
  @moduledoc """
  REST surface for the Today view — the unified "what do I do now" plan for the
  authenticated user. GET /api/v1/today?org_id=... (org_id optional; omit to
  span all the user's orgs).
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Today
  alias Therobotplans.Authz

  # GET /api/v1/today
  def show(conn, params) do
    user_id = get_user_id(conn)
    org_id = params["org_id"]

    # If an org is given, ensure the user is at least a viewer there.
    with :ok <- maybe_authorize(user_id, org_id) do
      plan =
        Today.plan(user_id, org_id: org_id, due_window_days: parse_int(params["due_window_days"]))

      json(conn, %{plan: plan})
    else
      err -> handle_error(conn, err)
    end
  end

  defp maybe_authorize(_user_id, nil), do: :ok

  defp maybe_authorize(user_id, org_id) do
    case Authz.authorize(user_id, "organization", org_id, "viewer") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp parse_int(nil), do: nil

  defp parse_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp handle_error(conn, err) do
    case err do
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
end
