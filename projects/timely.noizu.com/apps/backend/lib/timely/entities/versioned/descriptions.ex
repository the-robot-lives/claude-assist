defmodule Timely.Versioned.Descriptions do
  alias Timely.Versioned.Descriptions.Description, as: Entity
  alias Timely.Schema.Versioned.Descriptions.Description, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓁗𓈈𓎞𓆎⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Timely.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓐯𓁐𓄼𓊳⟧ get_versioned_description :: auto-generated pointer for public function get_versioned_description
  def get_versioned_description(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓐋𓍔𓎒𓐓⟧ create :: auto-generated pointer for public function create
  def create(description, context, options \\ []) do
    %Entity{}
    |> change(description)
    |> create(context, options)
  end

  # ⟦𓅻𓏂𓅱𓍫⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = description, attrs, context, options \\ []) do
    description
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓇷𓂓𓏋𓇶⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = description, context, options \\ []) do
    delete(description, context, options)
  end

  # ⟦𓇚𓍦𓅛𓄢⟧ change :: auto-generated pointer for public function change
  def change(%Entity{} = description, attrs \\ %{}) do
    attrs =
      Enum.map(attrs, fn
        {"title", value} -> {:title, value}
        {"body", value} -> {:body, value}
        {"id", value} -> {:id, value}
        {k, v} when is_atom(k) -> {k, v}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    Ecto.Changeset.change({description, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]}, attrs)
  end
end
