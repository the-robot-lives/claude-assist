defmodule Codefresh.Auth.TokenStore do
  @refresh_ttl 7 * 24 * 60 * 60
  @table :codefresh_refresh_jtis

  def store_refresh_jti(jti) when is_binary(jti) do
    case backend() do
      :memory ->
        ensure_table()
        :ets.insert(@table, {jti, expires_at()})
        :ok

      :redis ->
        Codefresh.Redis.set("refresh_jti:#{jti}", "1", ex: @refresh_ttl)
    end
  end

  def valid_refresh_jti?(jti) when is_binary(jti) do
    case backend() do
      :memory ->
        ensure_table()
        now = System.system_time(:second)

        case :ets.lookup(@table, jti) do
          [{^jti, expires_at}] when expires_at > now -> true
          [{^jti, _}] -> revoke_refresh_jti(jti) == :ok and false
          [] -> false
        end

      :redis ->
        case Codefresh.Redis.get("refresh_jti:#{jti}") do
          {:ok, "1"} -> true
          _ -> false
        end
    end
  end

  def revoke_refresh_jti(jti) when is_binary(jti) do
    case backend() do
      :memory ->
        ensure_table()
        :ets.delete(@table, jti)
        :ok

      :redis ->
        Codefresh.Redis.del("refresh_jti:#{jti}")
    end
  end

  defp backend, do: Application.get_env(:codefresh, :token_store, :redis)

  defp expires_at, do: System.system_time(:second) + @refresh_ttl

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, read_concurrency: true])
      _tid -> @table
    end
  rescue
    ArgumentError -> @table
  end
end
