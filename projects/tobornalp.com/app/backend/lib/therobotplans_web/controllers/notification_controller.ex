defmodule TherobotplansWeb.NotificationController do
  @moduledoc """
  REST surface for the notification inbox (human/frontend use). The MCP
  `tobornalp_notifications` server is the machine-facing surface; this is the
  human one for the inbox screen.
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Notifications
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/notifications?cursor=&max=&kinds[]=
  # The recipient is the authenticated user.
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [
          cursor: parse_int(params["cursor"]) || 0,
          max: parse_int(params["max"]) || 50,
          kinds: List.wrap(params["kinds"]),
          include_future: params["include_future"] == "true"
        ]

      case Notifications.get(org_id, user_id, opts) do
        {:ok, rows} ->
          next_cursor = if rows == [], do: opts[:cursor], else: List.last(rows).seq
          json(conn, %{notifications: Enum.map(rows, &to_json/1), next_cursor: next_cursor})

        {:throttled, ms} ->
          json(conn, %{notifications: [], throttled: true, retry_after_ms: ms})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/notifications/count
  def count(conn, %{"org_id" => org_id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      json(conn, %{unread: Notifications.count(org_id, user_id)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/notifications/mark_read  (body: {ids: [...]} or {} for all)
  def mark_read(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      ids = params["ids"] || :all
      {:ok, n} = Notifications.mark_read(org_id, user_id, ids)
      json(conn, %{marked_read: n})
    else
      err -> handle_error(conn, err)
    end
  end

  defp to_json(n) do
    %{id: n.id, seq: n.seq, kind: n.kind, sender: n.sender, subject_type: n.subject_type,
      subject_id: n.subject_id, body: n.body, payload: n.payload, seen: n.seen,
      read: n.read, inserted_at: n.inserted_at}
  end

  defp parse_int(nil), do: nil
  defp parse_int(n) when is_integer(n), do: n

  defp parse_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Organization not found"})
      {:error, :not_a_member} -> conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})
      _ -> conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
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
