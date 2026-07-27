defmodule TimelyWeb.TimelyAuth do
  @moduledoc """
  Workspace resolution for the Timely endpoints.

  Every Timely controller action begins here, because tenancy is the one thing
  none of them may get wrong. `with_workspace/4` resolves the caller's user id
  from the Guardian session, authorizes them against the requested workspace,
  and only then hands the action a context - so an action body cannot run
  against a workspace the caller does not belong to, even by mistake.

  The context it builds is also what `Timely.Sync.Mutations` reads for its
  `admin` decisions (conflict matrix row 19), so the role lookup happens once
  per request rather than once per mutation.
  """

  import Plug.Conn

  alias Timely.Sync.Workspace

  @doc """
  Resolves and authorizes the workspace, then calls `fun` with `{conn, ctx}`.

  Halts with the contract's error shape on every failure path: `401` with
  `code: token_expired` semantics left to the Guardian pipeline, `400` for a
  missing workspace, and `403` for a non-member.
  """
  # ⟦𓅱𓋴𓎡𓊪⟧ with_workspace :: Authorizes a workspace and builds the request context.
  def with_workspace(conn, workspace_id, opts \\ [], fun) do
    role = Keyword.get(opts, :role, "viewer")

    case current_user_id(conn) do
      nil ->
        error(conn, 401, "unauthorized", "authentication required")

      user_id ->
        cond do
          is_nil(workspace_id) or workspace_id == "" ->
            error(conn, 400, "workspace_required", "workspace_id is required")

          true ->
            case Workspace.authorize(user_id, workspace_id, role) do
              {:ok, _membership} ->
                fun.({conn, build_ctx(conn, user_id, workspace_id)})

              {:error, :not_a_member} ->
                # Deliberately indistinguishable from "no such workspace": a
                # non-member must not be able to probe which workspace ids exist.
                error(conn, 403, "forbidden", "not a member of this workspace")

              {:error, :insufficient_role} ->
                error(conn, 403, "forbidden", "insufficient role for this workspace")
            end
        end
    end
  end

  @doc "The authenticated user's id, or nil."
  # ⟦𓅱𓋴𓂋𓂧⟧ current_user_id :: The authenticated user id.
  def current_user_id(conn) do
    case Timely.Guardian.Plug.current_resource(conn) do
      %Timely.Users.Sessions.UserSession{user: {:ref, _module, id}} -> id
      %Timely.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  @doc "Renders the contract's `Error` shape."
  # ⟦𓆑𓂋𓂋𓋴⟧ error :: Renders the contract Error shape and halts.
  def error(conn, status, code, message, details \\ nil) do
    body = %{"code" => code, "message" => message}
    body = if details, do: Map.put(body, "details", details), else: body

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end

  defp build_ctx(conn, user_id, workspace_id) do
    %{
      workspace_id: workspace_id,
      user_id: user_id,
      device_id: device_id_header(conn),
      admin: admin?(user_id, workspace_id),
      atomic: false,
      now: DateTime.utc_now(),
      blob_url_builder: fn screenshot_id -> "/api/v1/screenshots/#{screenshot_id}/blob" end
    }
  end

  # Row 19 needs one bit: may this actor change workspace policy. Owner and
  # admin qualify; everyone else is refused at the mutation, not at the route,
  # because a batch may legitimately mix policy and non-policy mutations.
  defp admin?(user_id, workspace_id) do
    match?({:ok, _}, Timely.Organizations.authorize(user_id, workspace_id, "admin"))
  end

  defp device_id_header(conn) do
    case get_req_header(conn, "x-timely-device-id") do
      [value | _] -> value
      [] -> nil
    end
  end
end
