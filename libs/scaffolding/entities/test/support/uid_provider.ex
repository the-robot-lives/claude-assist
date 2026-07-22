defmodule Noizu.Entity.Test.UIDProvider do
  @moduledoc false
  @foo_type Noizu.UUID.uuid5(:dns, "#{Elixir.Noizu.Support.Entities.Foos.Foo}")
  # ⟦𓏆𓋌𓇖𓃟⟧ generate :: auto-generated pointer for public function generate
  def generate(_, _), do: {:ok, {:os.system_time(:millisecond) - 1_683_495_051_937, 0}}

  # ⟦𓋃𓊖𓁕𓍫⟧ ref :: auto-generated pointer for public function ref
  def ref({:id, id, :type_id, ref_type_field}) do
    cond do
      ref_type_field == @foo_type ->
        Elixir.Noizu.Support.Entities.Foos.Foo.ref(id)

      :else ->
        {:error, {:unsupported, __MODULE__, :ref}}
    end
  end

  def ref(_), do: {:error, {:unsupported, __MODULE__, :ref}}
end
