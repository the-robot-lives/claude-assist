defmodule Foryou.Auth.ApiKeys do
  @moduledoc """
  Context for Foryou.Auth.ApiKey — machine-to-machine API credentials.

  Secrets are only ever held in memory at mint time (returned once to the
  caller). At rest we store a sha256 of the full secret plus a short,
  non-secret `key_prefix` used to look up the row on verify.
  """
  alias Foryou.Auth.ApiKey, as: Entity
  alias Foryou.Schema.Auth.ApiKey, as: Schema
  use Noizu.Repo
  def_repo(entity: Foryou.Auth.ApiKey)

  @prefix_length 12

  @doc """
  Mints a new API key. Returns `{:ok, %Schema{}, secret}` where `secret` is the
  full plaintext key — shown only here, never recoverable.
  """
  def mint(owner_user_id, name, opts \\ []) do
    secret = "fk_live_" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
    key_prefix = String.slice(secret, 0, @prefix_length)

    attrs = %{
      owner_user_id: owner_user_id,
      name: name,
      key_prefix: key_prefix,
      token_hash: token_hash(secret),
      scopes: opts[:scopes] || ["*"],
      expires_at: opts[:expires_at],
      status: "active"
    }

    %Schema{}
    |> Schema.changeset(attrs)
    |> Foryou.Repo.insert()
    |> case do
      {:ok, record} -> {:ok, record, secret}
      error -> error
    end
  end

  @doc """
  Verifies a raw key. Looks up by prefix, then constant-time-compares the hash.
  Updates `last_used_at` on success. Returns `{:ok, %Schema{}}` or `{:error, :invalid}`.
  """
  def verify(nil), do: {:error, :invalid}
  def verify(""), do: {:error, :invalid}

  def verify(raw_key) when is_binary(raw_key) do
    key_prefix = String.slice(raw_key, 0, @prefix_length)
    expected = token_hash(raw_key)

    case Foryou.Repo.get_by(Schema, key_prefix: key_prefix) do
      %Schema{status: "active", revoked_at: nil, token_hash: hash} = record
      when is_binary(hash) ->
        if valid_expiry?(record) and Plug.Crypto.secure_compare(hash, expected) do
          mark_used(record)
          {:ok, record}
        else
          {:error, :invalid}
        end

      _ ->
        {:error, :invalid}
    end
  end

  @doc "Revokes a key by id."
  def revoke(id) do
    case Foryou.Repo.get(Schema, id) do
      nil ->
        {:error, :not_found}

      record ->
        record
        |> Schema.changeset(%{
          revoked_at: now(),
          status: "revoked"
        })
        |> Foryou.Repo.update()
    end
  end

  def list_for_user(user_id) do
    import Ecto.Query
    from(k in Schema, where: k.owner_user_id == ^user_id) |> Foryou.Repo.all()
  end

  defp valid_expiry?(%Schema{expires_at: nil}), do: true

  defp valid_expiry?(%Schema{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  defp mark_used(%Schema{} = record) do
    record
    |> Schema.changeset(%{last_used_at: now()})
    |> Foryou.Repo.update()
  end

  defp token_hash(secret) do
    :crypto.hash(:sha256, secret) |> Base.encode16(case: :lower)
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
