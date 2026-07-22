defmodule ForyouWeb.Plugs.CORS do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> maybe_put_allow_origin()
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "authorization, content-type")
    |> put_resp_header("access-control-max-age", "3600")
    |> handle_preflight()
  end

  # When an allowlist is configured (non-empty), only reflect Origins that are
  # in the list — unlisted origins get no access-control-allow-origin header.
  # When the allowlist is empty (dev/default), reflect any Origin.
  defp maybe_put_allow_origin(conn) do
    allowlist = Application.get_env(:foryou, :cors_origins, [])

    case {allowlist, request_origin(conn)} do
      {[], nil} ->
        put_resp_header(conn, "access-control-allow-origin", "*")

      {[], origin} ->
        put_resp_header(conn, "access-control-allow-origin", origin)

      {_list, nil} ->
        conn

      {list, origin} ->
        if origin in list do
          put_resp_header(conn, "access-control-allow-origin", origin)
        else
          conn
        end
    end
  end

  defp request_origin(conn) do
    case get_req_header(conn, "origin") do
      [origin | _] -> origin
      _ -> nil
    end
  end

  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn |> send_resp(204, "") |> halt()
  end

  defp handle_preflight(conn), do: conn
end
