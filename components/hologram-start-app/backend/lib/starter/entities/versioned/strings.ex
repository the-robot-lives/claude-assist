defmodule Starter.Versioned.Strings do
  alias Starter.Versioned.Strings.String, as: Entity
  alias Starter.Schema.Versioned.Strings.String, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓃨𓎑𓄖𓎕⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Starter.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓏹𓅣𓅊𓐆⟧ get_versioned_string :: auto-generated pointer for public function get_versioned_string
  def get_versioned_string(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓐮𓍋𓈨𓁼⟧ create :: auto-generated pointer for public function create
  def create(string, context, options \\ []) do
    %Entity{}
    |> change(string)
    |> create(context, options)
  end

  # ⟦𓇪𓄟𓌉𓃹⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = string, attrs, context, options \\ []) do
    string
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓏍𓋻𓉥𓋴⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = string, context, options \\ []) do
    delete(string, context, options)
  end

  # ⟦𓇕𓎖𓏙𓄬⟧ change :: auto-generated pointer for public function change
  def change(%Entity{} = string, attrs \\ %{}) do
    attrs =
      Enum.map(attrs, fn
        {"content", value} -> {:content, value}
        {"id", value} -> {:id, value}
        {k, v} when is_atom(k) -> {k, v}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    Ecto.Changeset.change({string, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]}, attrs)
  end
end
