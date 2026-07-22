# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2025 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Dummy.Entity.FieldProtocol do
  @fallback_to_any true
  # ⟦𓂺𓇚𓄡𓎧⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(field, field_settings, persistence_settings, context, options)
  # ⟦𓅖𓄅𓍹𓄈⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ---------------------------
  #
  # ---------------------------
  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    {:ok, {name, field}}
  end

  # ---------------------------
  #
  # ---------------------------
  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    {:ok, {name, get_in(record, [Access.key(as_name)])}}
  end
end
