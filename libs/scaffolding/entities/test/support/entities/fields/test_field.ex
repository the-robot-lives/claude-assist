defmodule Noizu.Support.Entity.TestField do
  @moduledoc false
  @derive Noizu.EntityReference.Protocol
  defstruct id: nil,
            sno: nil

  use Noizu.Entity.Field.Behaviour

  # ⟦𓃤𓃟𓏛𓌺⟧ id :: auto-generated pointer for public function id
  def id(%__MODULE__{id: id}), do: {:ok, id}
  # ⟦𓀧𓇰𓇈𓉺⟧ ref :: auto-generated pointer for public function ref
  def ref(%__MODULE__{id: id}), do: {:ok, {:ref, __MODULE__, id}}
  # ⟦𓉓𓊋𓏃𓃪⟧ sref :: auto-generated pointer for public function sref
  def sref(%__MODULE__{id: id}), do: {:ok, "ref.testfield.#{id}"}
  # ⟦𓌅𓎬𓇬𓅢⟧ kind :: auto-generated pointer for public function kind
  def kind(%__MODULE__{}), do: {:ok, __MODULE__}
  # ⟦𓏙𓀹𓁃𓂬⟧ entity :: auto-generated pointer for public function entity
  def entity(%__MODULE__{} = this, _), do: {:ok, this}

  # ⟦𓊤𓀳𓏎𓀓⟧ type__before_create :: auto-generated pointer for public function type__before_create
  def type__before_create(nil, _, _, _), do: nil

  def type__before_create(sno, _, _, _) when is_bitstring(sno) do
    entity = %__MODULE__{
      id: 0xF00BA7,
      sno: sno
    }

    {:ok, entity}
  end

  def type__before_create(%__MODULE__{} = this, _, _, _) do
    cond do
      this.id -> {:ok, this}
      :else -> {:ok, %{this | id: 31_337}}
    end
  end

  # ⟦𓋋𓇿𓐀𓏔⟧ type__before_update :: auto-generated pointer for public function type__before_update
  def type__before_update(nil, _, _, _), do: nil

  def type__before_update(sno, _, _, _) when is_bitstring(sno) do
    entity = %__MODULE__{
      id: 0xF00BA8,
      sno: sno
    }

    {:ok, entity}
  end

  def type__before_update(%__MODULE__{} = this, _, _, _) do
    {:ok, %{this | sno: this.sno <> "_updated"}}
  end

  # ⟦𓅠𓈯𓋑𓇽⟧ type__after_delete :: auto-generated pointer for public function type__after_delete
  def type__after_delete(_, _, _, _), do: nil
end

defmodule Noizu.Support.Entity.TestField.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ⟦𓎵𓁲𓀺𓆙⟧ persist :: auto-generated pointer for public function persist
  def persist(_, _, _, _, _), do: {:error, :not_supported}
  # ⟦𓃑𓐮𓇟𓅳⟧ as_record :: auto-generated pointer for public function as_record
  def as_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓃈𓋻𓏑𓉎⟧ fetch_as_entity :: auto-generated pointer for public function fetch_as_entity
  def fetch_as_entity(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓌓𓅛𓆯𓆤⟧ as_entity :: auto-generated pointer for public function as_entity
  def as_entity(_, _, _, _, _), do: {:error, :not_supported}
  # ⟦𓍒𓐐𓄘𓆏⟧ delete_record :: auto-generated pointer for public function delete_record
  def delete_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓋙𓎎𓇔𓀎⟧ from_record :: auto-generated pointer for public function from_record
  def from_record(_, _, _, _), do: {:error, :not_supported}
  # ⟦𓉭𓐭𓂺𓇤⟧ merge_from_record :: auto-generated pointer for public function merge_from_record
  def merge_from_record(_, _, _, _, _), do: {:error, :not_supported}

  # ⟦𓎫𓂿𓅫𓀤⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    # We need to do a universal ecto conversion
    [
      {:ok, {:"#{as_name}_id", field.id}},
      {:ok, {:"#{as_name}_sno", field.sno}}
    ]
  end

  # ⟦𓃤𓏻𓍯𓈍⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(
        _field_stub,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    id = Map.get(record, :"#{as_name}_id")
    sno = Map.get(record, :"#{as_name}_sno")

    {:ok, {name, %Noizu.Support.Entity.TestField{id: id, sno: sno}}}
  end
end

defimpl Noizu.Entity.Store.Ecto.EntityProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate fetch_as_entity(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Ecto.Entity.FieldProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.EntityProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate persist(entity, type, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate fetch_as_entity(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate as_entity(entity, record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate delete_record(entity, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate merge_from_record(entity, record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate from_record(record, settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end

defimpl Noizu.Entity.Store.Dummy.Entity.FieldProtocol, for: [Noizu.Support.Entity.TestField] do
  defdelegate field_from_record(
                field,
                record,
                field_settings,
                persistence_settings,
                context,
                options
              ),
              to: Noizu.Support.Entity.TestField.TypeHelper

  defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
    to: Noizu.Support.Entity.TestField.TypeHelper
end
