defmodule Noizu.Entity.TimeStamp do
  @moduledoc """
  TimeStamp custom field. This field is used to track inserted_at, updated_at, and deleted_at timestamp.
  """
  defstruct inserted_at: nil,
            updated_at: nil,
            deleted_at: nil

  use Noizu.Entity.Field.Behaviour

  # ⟦𓌺𓎴𓌘𓎥⟧ ecto_gen_string :: auto-generated pointer for public function ecto_gen_string
  def ecto_gen_string(name) do
    unless name in ["time_stamp", "root"] do
      {:ok,
       [
         "#{name}_inserted_at:utc_datetime_usec",
         "#{name}_updated_at:utc_datetime_usec",
         "#{name}_deleted_at:utc_datetime_usec"
       ]}
    else
      {:ok, ["deleted_at:utc_datetime_usec"]}
    end
  end

  # ⟦𓐀𓐔𓐭𓐮⟧ stub :: auto-generated pointer for public function stub
  def stub(), do: {:ok, %__MODULE__{}}

  # ⟦𓐤𓅊𓏃𓈧⟧ now :: auto-generated pointer for public function now
  def now(), do: now(DateTime.utc_now())
  def now(now), do: %__MODULE__{inserted_at: now, updated_at: now}

  # ⟦𓆟𓃷𓅮𓀟⟧ type_as_entity :: auto-generated pointer for public function type_as_entity
  def type_as_entity(nil, _context, options) do
    now = options[:current_time] || DateTime.utc_now()
    {:ok, %__MODULE__{inserted_at: now, updated_at: now}}
  end

  def type_as_entity(%__MODULE__{} = this, _context, options) do
    now = options[:current_time] || DateTime.utc_now()

    {:ok,
     %__MODULE__{this | inserted_at: this.inserted_at || now, updated_at: this.updated_at || now}}
  end
end

defmodule Noizu.Entity.TimeStamp.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ⟦𓏝𓀒𓆉𓄒⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓁱𓊺𓈔𓏜⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓁾𓀷𓏼𓄧⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(_, _, _, _, _), do: {:error, :not_supported}
  # ⟦𓉦𓎰𓄮𓍊⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓌝𓋰𓉸𓄩⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓂛𓂔𓆜𓈹⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(_, _, _, _, _), do: {:error, :not_supported}
  # ⟦𓎻𓍳𓄻𓌀⟧ persist :: auto-generated pointer for public function persist
  def persist(_, _, _, _, _), do: {:error, :not_supported}

  # ⟦𓇼𓀐𓂝𓇕⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name

    unless name in [:time_stamp, :root] do
      [
        {:ok, {:"#{name}_inserted_at", field.inserted_at}},
        {:ok, {:"#{name}_updated_at", field.updated_at}},
        {:ok, {:"#{name}_deleted_at", field.deleted_at}}
      ]
    else
      [
        {:ok, {:inserted_at, field.inserted_at}},
        {:ok, {:updated_at, field.updated_at}},
        {:ok, {:deleted_at, field.deleted_at}}
      ]
    end
  end

  # ⟦𓊎𓏳𓉞𓍶⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    unless as_name in [:time_stamp, :root] do
      field = %Noizu.Entity.TimeStamp{
        inserted_at: get_in(record, [Access.key(:"#{name}_inserted_at")]),
        updated_at: get_in(record, [Access.key(:"#{name}_updated_at")]),
        deleted_at: get_in(record, [Access.key(:"#{name}_deleted_at")])
      }

      {:ok, {name, field}}
    else
      field = %Noizu.Entity.TimeStamp{
        inserted_at: get_in(record, [Access.key(:inserted_at)]),
        updated_at: get_in(record, [Access.key(:updated_at)]),
        deleted_at: get_in(record, [Access.key(:deleted_at)])
      }

      {:ok, {name, field}}
    end
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_record(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper
  defdelegate fetch_as_entity(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Entity.TimeStamp] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_record(entity, settings, context, options), to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate fetch_as_entity(entity, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Entity.TimeStamp.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Entity.TimeStamp] do
  require Noizu.Entity.Meta.Field

  def field_from_record(
        _field,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name),
        _persistence_settings,
        _context,
        _options
      ) do
    {:ok, {name, get_in(record, [Access.key(name)])}}
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name) = _field_settings,
        _persistence_settings,
        _context,
        _options
      ) do
    {:ok, {name, field}}
  end
end
