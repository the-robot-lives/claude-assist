defmodule ForyouWeb.Management.ApiKeyController do
  @moduledoc """
  Management of API keys (API-key / system-level). The plaintext `secret` is
  returned only on create (mint) — it is never recoverable. Delete = revoke.
  """
  use ForyouWeb, :controller

  alias Foryou.Auth.ApiKeys
  alias Foryou.Schema.Auth.ApiKey
  import Ecto.Query

  def index(conn, _params) do
    keys =
      from(k in ApiKey, order_by: [desc: k.inserted_at])
      |> Foryou.Repo.all()

    json(conn, %{api_keys: Enum.map(keys, &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    case Foryou.Repo.get(ApiKey, id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      key -> json(conn, %{api_key: serialize(key)})
    end
  end

  def create(conn, %{"api_key" => params}) do
    owner_user_id =
      params["owner_user_id"] || get_in(conn.assigns, [:current_user, Access.key(:id)])

    opts =
      []
      |> then(&if params["scopes"], do: [{:scopes, params["scopes"]} | &1], else: &1)
      |> then(&if params["expires_at"], do: [{:expires_at, parse_dt(params["expires_at"])} | &1], else: &1)

    case ApiKeys.mint(owner_user_id, params["name"], opts) do
      {:ok, key, secret} ->
        conn
        |> put_status(:created)
        |> json(%{api_key: Map.put(serialize(key), :secret, secret)})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case ApiKeys.revoke(id) do
      {:ok, _} -> conn |> send_resp(:no_content, "")
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  defp serialize(%ApiKey{} = k) do
    %{
      id: k.id,
      name: k.name,
      key_prefix: k.key_prefix,
      scopes: k.scopes,
      status: k.status,
      expires_at: k.expires_at,
      last_used_at: k.last_used_at,
      inserted_at: k.inserted_at
    }
  end

  defp parse_dt(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_dt(_), do: nil

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
