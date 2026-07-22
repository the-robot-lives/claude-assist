defmodule Starter.Versioned.Descriptions do
  alias Starter.Versioned.Descriptions.Description, as: Entity
  alias Starter.Schema.Versioned.Descriptions.Description, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓍫𓍿𓊄𓎆⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Starter.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓋀𓈣𓐠𓇔⟧ get_versioned_description :: auto-generated pointer for public function get_versioned_description
  def get_versioned_description(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓎚𓁉𓈖𓁑⟧ create :: auto-generated pointer for public function create
  def create(description, context, options \\ []) do
    %Entity{}
    |> change(description)
    |> create(context, options)
  end

  # ⟦𓈺𓆨𓃢𓊖⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = description, attrs, context, options \\ []) do
    description
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓋪𓊶𓇹𓈇⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = description, context, options \\ []) do
    delete(description, context, options)
  end

  # ⟦𓉹𓎎𓃳𓀟⟧ change :: auto-generated pointer for public function change
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
