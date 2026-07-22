defmodule ForyouWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Authenticates machine-to-machine requests via an API key.

  Reads `Authorization: Bearer <key>`, falling back to `X-Api-Key`. On success
  assigns `:api_key`, `:current_user` (the key's owner), and `:context`
  (system-level — API keys grant full access to the management surface).
  """
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, raw_key} <- extract_key(conn),
         {:ok, key} <- Foryou.Auth.ApiKeys.verify(raw_key),
         {:ok, owner} <- load_owner(key.owner_user_id) do
      conn
      |> assign(:api_key, key)
      |> assign(:current_user, owner)
      |> assign(:context, Noizu.Context.system())
    else
      _ -> unauthorized(conn)
    end
  end

  defp extract_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] ->
        {:ok, String.trim(key)}

      _ ->
        case get_req_header(conn, "x-api-key") do
          [key | _] -> {:ok, String.trim(key)}
          _ -> :error
        end
    end
  end

  defp load_owner(user_id) do
    case Foryou.Repo.get(Foryou.Schema.Users.User, user_id) do
      nil -> :error
      user -> {:ok, user}
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{errors: %{detail: "Invalid API key"}}))
    |> halt()
  end
end
