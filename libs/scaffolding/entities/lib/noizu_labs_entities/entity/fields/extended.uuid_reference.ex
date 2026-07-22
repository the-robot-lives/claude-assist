defmodule Noizu.Entity.Extended.UUIDReference do
  @moduledoc """
  Field that is encoded on ecto using uuid and type fields.
  """

  @derive Noizu.EntityReference.Protocol
  defstruct reference: nil
  use Noizu.Entity.Field.Behaviour

  # ⟦𓅔𓄀𓎞𓄐⟧ ecto_gen_string :: auto-generated pointer for public function ecto_gen_string
  def ecto_gen_string(name) do
    {:ok, ["#{name}_ref:uuid", "#{name}_ref_type:uuid"]}
  end

  # ⟦𓏹𓍊𓎦𓁊⟧ id :: auto-generated pointer for public function id
  def id(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.id(reference)
  # ⟦𓄪𓋩𓏬𓃊⟧ ref :: auto-generated pointer for public function ref
  def ref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.ref(reference)
  # ⟦𓏢𓇔𓈸𓉢⟧ sref :: auto-generated pointer for public function sref
  def sref(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.sref(reference)
  # ⟦𓏥𓏙𓉭𓀆⟧ kind :: auto-generated pointer for public function kind
  def kind(%__MODULE__{reference: reference}), do: Noizu.EntityReference.Protocol.kind(reference)
  # ⟦𓎉𓎦𓋿𓂦⟧ entity :: auto-generated pointer for public function entity
  def entity(%__MODULE__{reference: reference}, context),
    do: Noizu.EntityReference.Protocol.entity(reference, context)

  # ⟦𓆉𓇬𓇵𓃇⟧ type_as_entity :: auto-generated pointer for public function type_as_entity
  def type_as_entity(this, _, _), do: {:ok, %__MODULE__{reference: this}}

  # ⟦𓉐𓈢𓇡𓏍⟧ stub :: auto-generated pointer for public function stub
  def stub(), do: {:ok, %__MODULE__{}}
end

defmodule Noizu.Entity.Extended.UUIDReference.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  # ⟦𓍧𓊗𓎿𓁒⟧ field_as_record :: auto-generated pointer for public function field_as_record
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
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, R.ref(id: id)} <- Noizu.EntityReference.Protocol.ref(field) do
      {:ok, {as_name, id}}
    end
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _,
        _
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal ecto conversion
    with {:ok, R.ref(module: m, id: id)} <- Noizu.EntityReference.Protocol.ref(field) do
      [
        {:ok, {:"#{as_name}_ref", id}},
        {:ok, {:"#{as_name}_ref_type", Noizu.UUID.uuid5(:dns, "#{m}")}}
      ]
    end
  end

  # ⟦𓇃𓄶𓎹𓏑⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(entity, record, field_settings, persistence_settings, context, options)

  def field_from_record(
        _,
        record,
        Noizu.Entity.Meta.Field.field_settings(
          options: field_options,
          name: name,
          store: field_store
        ),
        Noizu.Entity.Meta.Persistence.persistence_settings(
          store: store,
          table: table,
          type: Noizu.Entity.Store.Amnesia
        ),
        context,
        _
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    ref_field = get_in(record, [Access.key(:entity), Access.key(as_name)])

    cond do
      is_nil(ref_field) ->
        nil

      :else ->
        case ref_field do
          v when is_struct(v) ->
            {:ok, v}

          v = R.ref() ->
            if field_options[:auto] do
              Noizu.EntityReference.Protocol.entity(v, context)
            else
              Noizu.EntityReference.Protocol.ref(v)
            end

          v ->
            v
        end
    end
    |> case do
      nil -> {:ok, {name, nil}}
      {:ok, entity} -> {:ok, {name, entity}}
      v -> v
    end
  end

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
        _
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name

    ref_field_key = :"#{as_name}_ref"
    ref_type_field_key = :"#{as_name}_ref_type"

    ref_field = Map.get(record, ref_field_key)
    ref_type_field = Map.get(record, ref_type_field_key)

    cond do
      is_nil(ref_field) ->
        nil

      is_nil(ref_type_field) ->
        case ref_field do
          v when is_struct(v) ->
            {:ok, v}

          v = R.ref() ->
            if field_options[:auto] do
              Noizu.EntityReference.Protocol.entity(v, context)
            else
              Noizu.EntityReference.Protocol.ref(v)
            end

          v = <<_::binary-size(16)>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              if field_options[:auto] do
                Noizu.EntityReference.Protocol.entity(ref, context)
              else
                Noizu.EntityReference.Protocol.ref(ref)
              end
            end

          v =
              <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _,
                _, _, _, _, _, _, _, _, _, _>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              if field_options[:auto] do
                Noizu.EntityReference.Protocol.entity(ref, context)
              else
                Noizu.EntityReference.Protocol.ref(ref)
              end
            end

          v ->
            v
        end

      :else ->
        case ref_field do
          v when is_struct(v) ->
            {:ok, v}

          ref = R.ref() ->
            if field_options[:auto] do
              Noizu.EntityReference.Protocol.entity(ref, context)
            else
              Noizu.EntityReference.Protocol.ref(ref)
            end

          v = <<_::binary-size(16)>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref(v) do
              if field_options[:auto] do
                Noizu.EntityReference.Protocol.entity(ref, context)
              else
                Noizu.EntityReference.Protocol.ref(ref)
              end
            end

          v =
              <<_, _, _, _, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _, _, _, ?-, _, _,
                _, _, _, _, _, _, _, _, _, _>> ->
            with {:ok, ref} <- Noizu.Entity.UID.ref({:id, v, :type_id, ref_type_field}) do
              if field_options[:auto] do
                Noizu.EntityReference.Protocol.entity(ref, context)
              else
                Noizu.EntityReference.Protocol.ref(ref)
              end
            end

          v when is_integer(v) ->
            with {:ok, ref} <- Noizu.Entity.UID.ref({:id, v, :type_id, ref_type_field}) do
              if field_options[:auto] do
                Noizu.EntityReference.Protocol.entity(ref, context)
              else
                Noizu.EntityReference.Protocol.ref(ref)
              end
            end

          v ->
            v
        end
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
  type_helper = Noizu.Entity.Extended.UUIDReference.TypeHelper

  defimpl entity_field_protocol, for: [Noizu.Entity.Extended.UUIDReference] do
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
