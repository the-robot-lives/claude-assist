defmodule Starter.Versioned.Names do
  alias Starter.Versioned.Names.Name, as: Entity
  alias Starter.Schema.Versioned.Names.Name, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓍘𓄩𓂁𓁭⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Starter.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓈕𓇾𓏖𓆍⟧ get_versioned_name :: auto-generated pointer for public function get_versioned_name
  def get_versioned_name(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓃋𓎚𓃈𓊸⟧ create :: auto-generated pointer for public function create
  def create(name, context, options \\ []) do
    %Entity{}
    |> change(name)
    |> create(context, options)
  end

  # ⟦𓍕𓇍𓌞𓎙⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = name, attrs, context, options \\ []) do
    name
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓆳𓍍𓋦𓏄⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = name, context, options \\ []) do
    delete(name, context, options)
  end

  # ⟦𓐌𓇖𓃔𓂔⟧ change :: auto-generated pointer for public function change
  def change(%Entity{} = name, attrs \\ %{}) do
    attrs =
      Enum.map(attrs, fn
        {"first", value} -> {:first, value}
        {"middle", value} -> {:middle, value}
        {"last", value} -> {:last, value}
        {"id", value} -> {:id, value}
        {k, v} when is_atom(k) -> {k, v}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    Ecto.Changeset.change({name, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]}, attrs)
  end
end
