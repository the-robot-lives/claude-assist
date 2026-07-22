# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Dummy.EntityProtocol do
  @moduledoc false
  @fallback_to_any true
  require Noizu.Entity.Meta.Field

  # ⟦𓀺𓏱𓎋𓉹⟧ persist :: auto-generated pointer for public function persist
  def persist(entity, type, settings, context, options)
  # ⟦𓎲𓍃𓊶𓁱⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(entity, settings, context, options)
  # ⟦𓂝𓅜𓁵𓊗⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(entity, settings, context, options)
  # ⟦𓇥𓍀𓎤𓁑⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(entity, record, settings, context, options)
  # ⟦𓄼𓎮𓏴𓅑⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(entity, settings, context, options)
  # ⟦𓉵𓉦𓂭𓁭⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(record, settings, context, options)
  # ⟦𓊐𓂜𓀓𓐏⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(entity, record, settings, context, options)
end

defmodule Noizu.Entity.Store.Dummy.StorageLayer do
  @moduledoc false
  @table_name :dummy_storage_device

  # ⟦𓅽𓉺𓏪𓆅⟧ init :: auto-generated pointer for public function init
  def init do
    create_table()
  end

  defp create_table do
    case :ets.info(@table_name) do
      :undefined -> :ets.new(@table_name, [:public, :named_table])
      _ -> :ok
    end
  end

  # ⟦𓐓𓊬𓍐𓌛⟧ write :: auto-generated pointer for public function write
  def write(id, name_space, entity) do
    # IO.inspect(entity, label:  "WRITE #{id}:#{name_space}")
    create_table()
    key = {id, name_space}
    :ets.insert(@table_name, {key, entity})
  end

  # ⟦𓐍𓁌𓂌𓅰⟧ delete :: auto-generated pointer for public function delete
  def delete(id, name_space) do
    # IO.puts "delete #{id}:#{name_space}"
    create_table()
    key = {id, name_space}
    :ets.delete(@table_name, key)
  end

  # ⟦𓅉𓉒𓃛𓍦⟧ get :: auto-generated pointer for public function get
  def get(id, name_space) do
    # IO.puts "get #{id}:#{name_space}"
    create_table()
    key = {id, name_space}

    case :ets.lookup(@table_name, key) do
      [{_, entity}] -> {:ok, entity}
      [] -> {:error, :not_found}
    end
  end
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ---------------------------
  #
  # ---------------------------
  def persist(record, type, persistence_settings, context, options)

  def persist(
        %{id: id} = record,
        _,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        _,
        _
      ) do
    # Verify table match
    Noizu.Entity.Store.Dummy.StorageLayer.write(id, table, record)
  end

  def persist(_, _, _, _, _) do
    {:error, :pending}
  end

  # ---------------------------
  #
  # ---------------------------
  def as_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table) = settings,
        context,
        options
      ) do
    # @todo strip transient fields,
    # @todo collapse refs.
    # @todo map fields
    # @todo Inject indexes

    #     Record.defrecord(:field_settings, [name: nil, store: nil, type: nil, transient: false, pii: false, default: nil, acl: nil])
    fields =
      Noizu.Entity.Meta.fields(entity)
      |> Enum.map(fn
        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: nil) = field_settings} ->
          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_as_record(
            get_in(entity, [Access.key(name)]),
            field_settings,
            settings,
            context,
            options
          )

        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: {:ecto, _}) = field_settings} ->
          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_as_record(
            get_in(entity, [Access.key(name)]),
            field_settings,
            settings,
            context,
            options
          )

        {_, Noizu.Entity.Meta.Field.field_settings(name: name, type: type) = field_settings} ->
          {:ok, field_entry} =
            apply(type, :type_as_entity, [get_in(entity, [Access.key(name)]), context, options])

          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_as_record(
            field_entry,
            field_settings,
            settings,
            context,
            options
          )
      end)
      |> List.flatten()
      |> Enum.map(fn
        {:ok, v} -> v
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    record = struct(table, fields)
    {:ok, record}
  end

  # ---------------------------
  #
  # ---------------------------
  def fetch_as_entity(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table) = settings,
        context,
        options
      ) do
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity),
         {:ok, record} <- Noizu.Entity.Store.Dummy.StorageLayer.get(id, table) do
      from_record(record, settings, context, options)
    end
  end

  # ---------------------------
  #
  # ---------------------------
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
  def delete_record(
        entity,
        Noizu.Entity.Meta.Persistence.persistence_settings(table: table),
        _context,
        _options
      ) do
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(entity) do
      Noizu.Entity.Store.Dummy.StorageLayer.delete(id, table)
      :ok
    end
  end

  # ---------------------------
  #
  # ---------------------------
  def merge_from_record(_, record, settings, context, options) do
    # todo refresh entity from record
    from_record(record, settings, context, options)
  end

  def from_record(
        record,
        Noizu.Entity.Meta.Persistence.persistence_settings(kind: kind) = settings,
        context,
        options
      ) do
    fields =
      Noizu.Entity.Meta.fields(kind)
      |> Enum.map(fn
        {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: nil) = field_settings} ->
          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_from_record(
            nil,
            record,
            field_settings,
            settings,
            context,
            options
          )

        {_,
         Noizu.Entity.Meta.Field.field_settings(name: _name, type: {:ecto, _}) = field_settings} ->
          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_from_record(
            nil,
            record,
            field_settings,
            settings,
            context,
            options
          )

        {_, Noizu.Entity.Meta.Field.field_settings(name: _name, type: type) = field_settings} ->
          {:ok, stub} = apply(type, :stub, [])

          Noizu.Entity.Store.Dummy.Entity.FieldProtocol.field_from_record(
            # used for matching
            stub,
            record,
            field_settings,
            settings,
            context,
            options
          )
      end)
      |> List.flatten()
      |> Enum.map(fn
        {:ok, v} -> v
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    entity = struct(kind, fields)
    {:ok, entity}
  end
end
