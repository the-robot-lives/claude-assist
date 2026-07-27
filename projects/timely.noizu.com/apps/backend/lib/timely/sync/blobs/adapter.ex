defmodule Timely.Sync.Blobs.Adapter do
  @moduledoc """
  Where screenshot bytes physically live.

  The indirection exists so the privacy gate in `Timely.Sync.Blobs` can be
  exercised end to end in tests without a network round trip. The gate is the
  part with the interesting failure mode; the bytes just need somewhere to go.
  """

  @callback put(key :: String.t(), body :: binary(), content_type :: String.t()) ::
              :ok | {:error, term()}
  @callback get(key :: String.t()) :: {:ok, binary()} | {:error, term()}
  @callback delete(key :: String.t()) :: :ok | {:error, term()}
end

defmodule Timely.Sync.Blobs.S3 do
  @moduledoc "Production blob store: the same S3/MinIO bucket the scaffold uses."
  @behaviour Timely.Sync.Blobs.Adapter

  @impl true
  # ⟦𓊪𓅱𓏏𓋴⟧ put :: Writes an object to S3.
  def put(key, body, content_type) do
    config = config()

    config[:bucket]
    |> ExAws.S3.put_object(key, body, content_type: content_type)
    |> ExAws.request(config)
    |> case do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  # ⟦𓎼𓏏𓋴𓊃⟧ get :: Reads an object from S3.
  def get(key) do
    config = config()

    config[:bucket]
    |> ExAws.S3.get_object(key)
    |> ExAws.request(config)
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  # ⟦𓂧𓃭𓏏𓋴⟧ delete :: Deletes an object from S3.
  def delete(key) do
    case Timely.Storage.delete_object(key) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp config, do: Application.get_env(:timely, Timely.Storage, [])
end

defmodule Timely.Sync.Blobs.Memory do
  @moduledoc """
  In-process blob store for tests.

  Backed by a public ETS table rather than a GenServer so a write made inside a
  test's Ecto sandbox transaction is visible to the assertion that follows,
  without ownership handoff.
  """
  @behaviour Timely.Sync.Blobs.Adapter

  @table :timely_blob_memory

  @doc "Creates the backing table. Safe to call repeatedly."
  # ⟦𓋴𓏏𓂋𓏏⟧ setup :: Creates the in-memory blob table.
  def setup do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, :set])
    end

    :ok
  end

  @doc "Drops every stored object."
  # ⟦𓂋𓋴𓏏𓋴⟧ reset :: Clears the in-memory blob table.
  def reset do
    setup()
    :ets.delete_all_objects(@table)
    :ok
  end

  @impl true
  def put(key, body, _content_type) do
    setup()
    :ets.insert(@table, {key, body})
    :ok
  end

  @impl true
  def get(key) do
    setup()

    case :ets.lookup(@table, key) do
      [{^key, body}] -> {:ok, body}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def delete(key) do
    setup()
    :ets.delete(@table, key)
    :ok
  end
end
