defmodule Noizu.Entity.Path do
  @moduledoc """
  Entity field for encoding path data.
  """

  defstruct path: nil,
            materialized_path: nil,
            matrix: nil,
            depth: nil

  @identity_matrix %{
    a11: 1,
    a12: 0,
    a21: 0,
    a22: 1
  }
  use Noizu.Entity.Field.Behaviour

  # ⟦𓃥𓌆𓌀𓅮⟧ ecto_gen_string :: auto-generated pointer for public function ecto_gen_string
  def ecto_gen_string(name) do
    {:ok,
     [
       "#{name}_depth:integer",
       "#{name}_a11:integer",
       "#{name}_a12:integer",
       "#{name}_a21:integer",
       "#{name}_a22:integer"
     ]}
  end

  # ⟦𓀇𓈞𓄚𓇿⟧ parent_path :: auto-generated pointer for public function parent_path
  def parent_path(nil), do: nil

  def parent_path(%{__struct__: __MODULE__} = this) do
    new(Enum.slice(this.path, 0..-2//-1))
  end

  # ⟦𓉋𓄭𓋖𓌰⟧ path_string :: auto-generated pointer for public function path_string
  def path_string(nil), do: nil

  def path_string(%{__struct__: __MODULE__} = this) do
    Enum.join(this.path, ".")
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓀤𓇄𓅁𓋷⟧ position_matrix :: auto-generated pointer for public function position_matrix
  def position_matrix(position) when is_integer(position) do
    i = position + 1

    %{
      a11: i,
      a12: -1,
      a21: 1,
      a22: 0
    }
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓉛𓐓𓁸𓂙⟧ multiply_matrix :: auto-generated pointer for public function multiply_matrix
  def multiply_matrix(%{a11: a11, a12: a12, a21: a21, a22: a22}, %{
        a11: b11,
        a12: b12,
        a21: b21,
        a22: b22
      }) do
    %{
      a11: a11 * b11 + a12 * b21,
      a12: a11 * b12 + a12 * b22,
      a21: a21 * b11 + a22 * b21,
      a22: a21 * b12 + a22 * b22
    }
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓁣𓅥𓇊𓄵⟧ leaf_node :: auto-generated pointer for public function leaf_node
  def leaf_node(%{a11: a11, a12: a12, a21: _a21, a22: _a22}) do
    Integer.floor_div(a11, -a12)
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓈞𓎑𓁥𓁺⟧ convert_path_to_matrix :: auto-generated pointer for public function convert_path_to_matrix
  def convert_path_to_matrix([]), do: @identity_matrix

  def convert_path_to_matrix(path) when is_list(path) do
    Enum.reduce(
      path,
      @identity_matrix,
      fn position, path ->
        multiply_matrix(path, position_matrix(position))
      end
    )
  end

  # ---------------------------
  # child
  # ---------------------------
  # ⟦𓀑𓆿𓏲𓏡⟧ child :: auto-generated pointer for public function child
  def child(path, position) do
    np = path.path ++ [position]

    %__MODULE__{
      depth: path.depth + 1,
      path: np,
      materialized_path: convert_path_to_tuple(np),
      matrix: multiply_matrix(path.matrix, position_matrix(position))
    }
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓐆𓀀𓆨𓉴⟧ convert_matrix_to_path :: auto-generated pointer for public function convert_matrix_to_path
  def convert_matrix_to_path(m) do
    convert_matrix_to_path(m, [])
  end

  def convert_matrix_to_path(%{a11: 1, a12: 0, a21: 0, a22: 1}, acc) do
    Enum.reverse(acc)
  end

  def convert_matrix_to_path(m, acc) do
    if m.a22 == 0 do
      Enum.reverse(acc ++ [m.a11 - 1])
    else
      if length(acc) < 1024 do
        l = leaf_node(m)
        a11 = -m.a12
        a21 = -m.a22
        a12 = m.a11 - a11 * (l + 1)
        a22 = m.a21 - a21 * (l + 1)
        convert_matrix_to_path(%{a11: a11, a12: a12, a21: a21, a22: a22}, acc ++ [l])
      else
        {:error, acc}
      end
    end
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓁞𓉡𓁆𓏃⟧ convert_tuple_to_path :: auto-generated pointer for public function convert_tuple_to_path
  def convert_tuple_to_path(path) when is_tuple(path) do
    convert_tuple_to_path(path, [])
  end

  def convert_tuple_to_path({}, acc), do: acc
  def convert_tuple_to_path({a}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, {}}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, b}, acc), do: convert_tuple_to_path(b, acc ++ [a])

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓉽𓇅𓆱𓏥⟧ convert_path_to_tuple :: auto-generated pointer for public function convert_path_to_tuple
  def convert_path_to_tuple(path) when is_list(path) do
    path
    |> Enum.reverse()
    |> Enum.reduce({}, &{&1, &2})
  end

  # ---------------------------
  #
  # ---------------------------
  # ⟦𓀁𓌷𓆮𓏽⟧ new :: auto-generated pointer for public function new
  def new(%{path_a11: a11, path_a12: a12, path_a21: a21, path_a22: a22}) do
    new(%{a11: a11, a12: a12, a21: a21, a22: a22})
  end

  def new(%{a11: a11, a12: a12, a21: a21, a22: a22} = _m) when a12 > 0 and a22 > 0 do
    new(%{a11: a11, a12: -a12, a21: a21, a22: -a22})
  end

  def new(%{a11: _a11, a12: _a12, a21: _a21, a22: _a22} = m) do
    new(convert_matrix_to_path(m))
  end

  def new(path) when is_tuple(path) do
    new(convert_tuple_to_path(path))
  end

  def new(path) when is_list(path) do
    %__MODULE__{
      depth: length(path),
      path: path,
      materialized_path: convert_path_to_tuple(path),
      matrix: convert_path_to_matrix(path)
    }
  end

  def new("") do
    %__MODULE__{
      depth: 0,
      path: [],
      materialized_path: {},
      matrix: @identity_matrix
    }
  end

  def new(path) when is_bitstring(path) do
    path
    |> String.split(".")
    |> Enum.map(&String.to_integer(&1))
    |> new()
  end
end

defmodule Noizu.Entity.Path.TypeHelper do
  @moduledoc false
  require Noizu.Entity.Meta.Persistence
  require Noizu.Entity.Meta.Field

  # ⟦𓌇𓆉𓈨𓉽⟧ field_as_record :: auto-generated pointer for public function field_as_record
  def field_as_record(field, field_settings, persistence_settings, context, options)

  def field_as_record(
        _,
        Noizu.Entity.Meta.Field.field_settings(),
        Noizu.Entity.Meta.Persistence.persistence_settings(type: Noizu.Entity.Store.Amnesia),
        _,
        _
      ) do
    {:error, :simple}
  end

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(
          store: store,
          table: table
        ),
        _,
        _
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name

    [
      {:ok, {:"#{name}_depth", field.depth}},
      {:ok, {:"#{name}_a11", field.matrix.a11}},
      {:ok, {:"#{name}_a12", field.matrix.a12}},
      {:ok, {:"#{name}_a21", field.matrix.a21}},
      {:ok, {:"#{name}_a22", field.matrix.a22}}
    ]
  end

  # ⟦𓀹𓆨𓎉𓅺⟧ field_from_record :: auto-generated pointer for public function field_from_record
  def field_from_record(entity, record, field_settings, persistence_settings, context, options)

  def field_from_record(
        _,
        _,
        Noizu.Entity.Meta.Field.field_settings(),
        Noizu.Entity.Meta.Persistence.persistence_settings(type: Noizu.Entity.Store.Amnesia),
        _,
        _
      ) do
    {:error, :simple}
  end

  def field_from_record(
        _,
        record,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table),
        _,
        _
      ) do
    as_name = field_store[table][:name] || field_store[store][:name] || name
    depth = Map.get(record, :"#{as_name}_depth")
    a11 = Map.get(record, :"#{as_name}_a11")
    a12 = Map.get(record, :"#{as_name}_a12")
    a21 = Map.get(record, :"#{as_name}_a21")
    a22 = Map.get(record, :"#{as_name}_a22")
    entity = Noizu.Entity.Path.new(%{a11: a11, a12: a12, a21: a21, a22: a22, depth: depth})
    {:ok, {name, entity}}
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
  type_helper = Noizu.Entity.Path.TypeHelper

  defimpl entity_field_protocol, for: [Noizu.Entity.Path] do
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
