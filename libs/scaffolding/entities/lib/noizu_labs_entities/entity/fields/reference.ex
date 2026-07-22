defmodule Noizu.Entity.Reference do
  @moduledoc """
  A entity field type that is persisted as a ref/id of another field.
  """

  @derive Noizu.EntityReference.Protocol
  defstruct reference: nil
  use Noizu.Entity.Field.Behaviour

  # ⟦𓇪𓊮𓃓𓊐⟧ ecto_gen_string :: auto-generated pointer for public function ecto_gen_string
  def ecto_gen_string(name) do
    {:ok, "#{name}:integer"}
  end

  # ⟦𓀿𓉾𓍐𓀷⟧ id :: auto-generated pointer for public function id
  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  # ⟦𓃓𓈹𓂨𓆨⟧ ref :: auto-generated pointer for public function ref
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)
  # ⟦𓋛𓌶𓏜𓁥⟧ sref :: auto-generated pointer for public function sref
  def sref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.sref(reference)
  # ⟦𓏹𓉓𓈿𓂩⟧ kind :: auto-generated pointer for public function kind
  def kind(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.sref(reference)
  # ⟦𓍽𓎓𓏥𓊦⟧ entity :: auto-generated pointer for public function entity
  def entity(%__MODULE__{reference: reference}, context),
    do: Noizu.EntityReference.Protocol.entity(reference, context)

  # ⟦𓅄𓉔𓃣𓅵⟧ type_as_entity :: auto-generated pointer for public function type_as_entity
  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}
  # ⟦𓉝𓐐𓎌𓁤⟧ stub :: auto-generated pointer for public function stub
  def stub(), do: {:ok, %__MODULE__{}}

  # *******************************************
  # *******************************************
  # Ecto.Type support
  # *******************************************
  # *******************************************
  use Ecto.Type

  # ----------------------------
  # type
  # ----------------------------
  @doc false
  # ⟦𓂰𓉯𓋃𓈛⟧ type :: auto-generated pointer for public function type
  def type, do: :integer

  # ----------------------------
  # cast
  # ----------------------------
  @doc """
  Casts to Ref.
  """
  # ⟦𓐐𓁂𓁅𓀊⟧ cast :: Casts to Ref.
  def cast(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      is_integer(v) -> Noizu.Entity.UID.ref(v)
      is_struct(v) -> Noizu.EntityReference.Protocol.ref(v)
      :else -> :error
    end
  end

  # ----------------------------
  # cast!
  # ----------------------------
  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  # ⟦𓍚𓍆𓈎𓇹⟧ cast! :: Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  def cast!(value) do
    case cast(value) do
      {:ok, v} -> v
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  # ----------------------------
  # dump
  # ----------------------------
  @doc false
  # ⟦𓄓𓁀𓋉𓇛⟧ dump :: auto-generated pointer for public function dump
  def dump(v) when is_integer(v) do
    {:ok, v}
  end

  def dump(v) when is_nil(v) do
    {:ok, v}
  end

  def dump(v) do
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(v) do
      {:ok, id}
    else
      _ ->
        {:ok, 0}
    end
  end

  # ----------------------------
  # load
  # ----------------------------
  # ⟦𓏇𓍅𓂕𓃼⟧ load :: auto-generated pointer for public function load
  def load(v) do
    cond do
      v == nil -> {:ok, nil}
      v == 0 -> {:ok, nil}
      is_integer(v) -> Noizu.Entity.UID.ref(v)
      is_struct(v) -> Noizu.EntityReference.Protocol.ref(v)
      :else -> raise ArgumentError, "Unsupported #{__MODULE__} - #{inspect(v)}"
    end
  end
end

defmodule Noizu.Entity.Reference.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  # ⟦𓆧𓐕𓀽𓌻⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(field, field_settings, persistence_settings, context, options)

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(
          store: store,
          table: table,
          type: Noizu.Entity.Store.Amnesia
        ),
        _,
        _
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, ref} <- Noizu.EntityReference.Protocol.ref(field) do
      {:ok, {name, ref}}
    end
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _,
        _
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, id} <- Noizu.EntityReference.Protocol.id(field) do
      {:ok, {name, id}}
    end
  end

  # ⟦𓏪𓈁𓏜𓅧⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(
        _,
        record,
        Noizu.Entity.Meta.Field.field_settings(
          options: field_options,
          name: name,
          store: field_store
        ),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        context,
        _options
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    case Map.get(record, as_name) do
      v when is_struct(v) ->
        {:ok, v}

      v = R.ref() ->
        if field_options[:auto] do
          Noizu.EntityReference.Protocol.entity(v, context)
        else
          Noizu.EntityReference.Protocol.ref(v)
        end

      v when is_integer(v) ->
        v = Noizu.Entity.UID.ref(v)

        if field_options[:auto] do
          Noizu.EntityReference.Protocol.entity(v, context)
        else
          Noizu.EntityReference.Protocol.ref(v)
        end

      v ->
        v
    end
    |> case do
      nil -> {:ok, {name, nil}}
      {:ok, entity} -> {:ok, {name, entity}}
      v -> v
    end
  end
end

for store <- [
      Noizu.Entity.Store.Amnesia,
      Noizu.Entity.Store.Dummy,
      Noizu.Entity.Store.Ecto,
      Noizu.Entity.Store.Mnesia,
      Noizu.Entity.Store.Redis
    ] do
  entity_protocol = Module.concat(store, EntityProtocol)
  entity_field_protocol = Module.concat(store, Entity.FieldProtocol)
  type_helper = Noizu.Entity.Reference.TypeHelper

  defimpl entity_field_protocol, for: [Noizu.Entity.Reference] do
    @type_helper type_helper
    defdelegate field_from_record(
                  field,
                  record,
                  field_settings,
                  persistence_settings,
                  context,
                  options
                ),
                to: @type_helper

    defdelegate field_as_record(field, field_settings, persistence_settings, context, options),
      to: @type_helper
  end
end
