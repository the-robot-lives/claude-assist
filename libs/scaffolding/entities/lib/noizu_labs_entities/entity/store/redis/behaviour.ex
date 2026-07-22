# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defmodule Noizu.Entity.Store.Redis.EntityProtocol.Behaviour do
  @moduledoc """
  Support for Redis backed Entities.
  """

  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓋂𓇸𓍢𓉴⟧ key :: auto-generated pointer for public function key
  def key(entity, _settings, _context, _options) do
    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(entity) do
      key = "#{sref}.redis_store"
      {:ok, key}
    end
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓈪𓀱𓏄𓌤⟧ persist :: auto-generated pointer for public function persist
  def persist(entity, type, persistence_settings, context, options)

  def persist(
        entity,
        _,
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store) = settings,
        context,
        options
      ) do
    with {:ok, key} <- key(entity, settings, context, options),
         {:ok, redis_entity} <- as_record(entity, settings, context, options) do
      apply(store, :set_binary, [key, redis_entity])
      {:ok, entity}
    end
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓈀𓉜𓈟𓐃⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: _table),
        _context,
        _options
      ) do
    # @todo strip transient fields,
    # @todo collapse refs.
    # @todo map fields
    # @todo Inject indexes
    {:ok, entity}
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓄰𓈊𓏆𓏸⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store) = settings,
        context,
        options
      ) do
    with {:ok, key} <- key(entity, settings, context, options),
         {:ok, redis_entity} <- apply(store, :get_binary, [key]),
         true <- (redis_entity && true) || {:error, :not_found},
         {:ok, entity} <- from_record(redis_entity, settings, context, options) do
      {:ok, entity}
    end
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓎒𓋔𓐞𓎿⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(
        _,
        record,
        Noizu.Entity.Meta.Persistence.persistence_settings() = settings,
        context,
        options
      ) do
    from_record(record, settings, context, options)
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓊬𓃽𓋨𓐪⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store) = settings,
        context,
        options
      ) do
    with {:ok, key} <- key(entity, settings, context, options),
         :ok <- apply(store, :delete, [key]) do
      {:ok, entity}
    end
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓌈𓄣𓎳𓊿⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(_, record, settings, context, options) do
    # todo refresh entity
    from_record(record, settings, context, options)
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓈯𓈉𓂍𓂮⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(nil, _, _context, _options) do
    {:error, :not_found}
  end

  # ---------------------------
  #
  # ---------------------------
  def from_record(record, _, _context, _options) do
    {:ok, record}
  end

  # ⟦𓎸𓉌𓂌𓄹⟧ __using__ :: auto-generated pointer for public function __using__
  defmacro __using__(_) do
    quote do
      @behaviour Noizu.Entity.Store.Redis.EntityProtocol.Behaviour
      defdelegate key(record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate persist(record, action, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate as_record(record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate fetch_as_entity(record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate as_entity(entity, record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate delete_record(record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate from_record(record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defdelegate merge_from_record(entity, record, settings, context, options),
        to: Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defoverridable key: 4,
                     persist: 5,
                     as_record: 4,
                     fetch_as_entity: 4,
                     as_entity: 5,
                     delete_record: 4,
                     from_record: 4,
                     merge_from_record: 5
    end
  end
end
