# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Mnesia.Entity.FieldProtocol do
  @fallback_to_any true
  # ⟦𓍥𓁉𓅓𓅌⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(field, field_settings, persistence_settings, context, options)
  # ⟦𓍴𓅹𓇪𓌀⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(field, record, field_settings, persistence_settings, context, options)
end
