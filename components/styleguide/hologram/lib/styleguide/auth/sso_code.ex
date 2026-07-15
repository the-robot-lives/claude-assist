defmodule Styleguide.Auth.SSOCode do
  @moduledoc """
  One-time codes after Authentik OIDC — bridges Phoenix callback → Hologram page
  so user identity is written with Hologram.Server.put_cookie (readable by pages).
  """
  use GenServer

  @table :styleguide_sso_codes
  @ttl_ms 120_000

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create(user) when is_map(user) do
    code = Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
    expires = System.system_time(:millisecond) + @ttl_ms
    true = :ets.insert(@table, {code, user, expires})
    {:ok, code}
  end

  def exchange(code) when is_binary(code) do
    now = System.system_time(:millisecond)

    case :ets.lookup(@table, code) do
      [{^code, user, expires}] when expires > now ->
        :ets.delete(@table, code)
        {:ok, user}

      [{^code, _user, _expires}] ->
        :ets.delete(@table, code)
        {:error, :expired}

      [] ->
        {:error, :invalid}
    end
  end

  def exchange(_), do: {:error, :invalid}

  @impl true
  def init(:ok) do
    table =
      case :ets.whereis(@table) do
        :undefined ->
          :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])

        ref ->
          ref
      end

    {:ok, %{table: table}}
  end
end
