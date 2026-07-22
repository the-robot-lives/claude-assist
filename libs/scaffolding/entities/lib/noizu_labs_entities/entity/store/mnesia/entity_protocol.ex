# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Mnesia.EntityProtocol do
  @fallback_to_any true
  require Noizu.Entity.Meta.Field

  # ⟦𓁬𓍘𓀃𓊧⟧ persist :: auto-generated pointer for public function persist
  def persist(entity, type, settings, context, options)
  # ⟦𓁗𓁡𓀌𓈼⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(entity, settings, context, options)
  # ⟦𓍀𓍭𓇲𓅆⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(entity, settings, context, options)
  # ⟦𓎛𓇺𓇹𓊿⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(entity, record, settings, context, options)
  # ⟦𓐫𓁃𓀷𓊾⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(entity, settings, context, options)
  # ⟦𓊘𓇥𓈢𓏴⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(record, settings, context, options)
  # ⟦𓌔𓎕𓍸𓃮⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(entity, record, settings, context, options)
end
