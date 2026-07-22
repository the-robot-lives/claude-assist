defmodule GottaCc.Versioned.Strings do
  alias GottaCc.Versioned.Strings.String, as: Entity
  alias GottaCc.Schema.Versioned.Strings.String, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd
    GottaCc.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  def get_versioned_string(id, context, options \\ []), do: get(id, context, options)

  def create(string, context, options \\ [])

  # An already-built entity struct (or changeset) is handed straight to the
  # framework create (super -> Noizu.Repo.Meta.create). Routing a struct
  # through change/2 would Enum.map over the struct and raise `Enumerable not
  # implemented`. The attrs-map clause keeps the change/2 build path.
  def create(%Ecto.Changeset{} = changeset, context, options),
    do: super(changeset, context, options)

  def create(%Entity{} = string, context, options), do: super(string, context, options)

  def create(attrs, context, options) do
    %Entity{}
    |> change(attrs)
    |> super(context, options)
  end

  def update(%Entity{} = string, attrs, context, options \\ []) do
    string
    |> change(attrs)
    |> update(context, options)
  end

  def delete(%Entity{} = string, context, options \\ []) do
    delete(string, context, options)
  end

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
