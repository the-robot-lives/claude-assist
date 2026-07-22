# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Redis.EntityProtocol do
  @fallback_to_any true
  require Noizu.Entity.Meta.Field

  # ⟦𓂊𓈀𓃍𓆼⟧ persist :: auto-generated pointer for public function persist
  def persist(entity, type, settings, context, options)
  # ⟦𓇠𓉎𓈜𓀜⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(entity, settings, context, options)
  # ⟦𓊱𓋕𓌬𓋀⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(entity, settings, context, options)
  # ⟦𓁄𓋯𓍎𓃪⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(entity, record, settings, context, options)
  # ⟦𓀚𓈔𓃨𓎌⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(entity, settings, context, options)
  # ⟦𓌦𓈋𓉼𓌹⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(record, settings, context, options)
  # ⟦𓂢𓃐𓋈𓈯⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(entity, record, settings, context, options)
  # ⟦𓈤𓌣𓏔𓇼⟧ key :: auto-generated pointer for public function key
  def key(entity, settings, context, options)
end

defimpl Noizu.Entity.Store.Redis.EntityProtocol, for: [Any] do
  require Noizu.Entity.Meta.Persistence

  # ⟦𓇚𓆞𓁵𓇰⟧ __deriving__ :: auto-generated pointer for public function __deriving__
  defmacro __deriving__(module, _struct, _options) do
    quote do
      use Noizu.Entity.Store.Redis.EntityProtocol.Behaviour

      defimpl Noizu.Entity.Store.Redis.EntityProtocol, for: [unquote(module)] do
        def key(record, settings, context, options),
          do: apply(unquote(module), :key, [record, settings, context, options])

        def persist(record, action, settings, context, options),
          do: apply(unquote(module), :persist, [record, action, settings, context, options])

        def as_record(record, settings, context, options),
          do: apply(unquote(module), :as_record, [record, settings, context, options])

        def fetch_as_entity(record, settings, context, options),
          do: apply(unquote(module), :fetch_as_entity, [record, settings, context, options])

        def as_entity(entity, record, settings, context, options),
          do: apply(unquote(module), :as_entity, [entity, record, settings, context, options])

        def delete_record(record, settings, context, options),
          do: apply(unquote(module), :delete_record, [record, settings, context, options])

        def from_record(record, settings, context, options),
          do: apply(unquote(module), :from_record, [record, settings, context, options])

        def merge_from_record(entity, record, settings, context, options),
          do: apply(unquote(module), :from_record, [entity, record, settings, context, options])
      end
    end
  end

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
end
