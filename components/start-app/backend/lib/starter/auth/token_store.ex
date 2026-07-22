defmodule Starter.Auth.TokenStore do
  @refresh_ttl 7 * 24 * 60 * 60

  # ⟦𓐂𓃸𓉕𓋱⟧ store_refresh_jti :: auto-generated pointer for public function store_refresh_jti
  def store_refresh_jti(jti) when is_binary(jti) do
    Starter.Redis.set("refresh_jti:#{jti}", "1", ex: @refresh_ttl)
  end

  # ⟦𓁻𓋊𓀈𓃟⟧ valid_refresh_jti? :: auto-generated pointer for public function valid_refresh_jti?
  def valid_refresh_jti?(jti) when is_binary(jti) do
    case Starter.Redis.get("refresh_jti:#{jti}") do
      {:ok, "1"} -> true
      _ -> false
    end
  end

  # ⟦𓐤𓈤𓉹𓁪⟧ revoke_refresh_jti :: auto-generated pointer for public function revoke_refresh_jti
  def revoke_refresh_jti(jti) when is_binary(jti) do
    Starter.Redis.del("refresh_jti:#{jti}")
  end
end
