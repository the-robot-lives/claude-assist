defmodule GottaCc.Users.Sessions do
  @moduledoc """
  Context for GottaCc.Users.Sessions
  """
  alias GottaCc.Users.Sessions.UserSession, as: Entity
  alias GottaCc.Schema.Users.Sessions.UserSession, as: Schema
  use Noizu.Repo
  def_repo(entity: GottaCc.Users.Sessions.UserSession)

  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    GottaCc.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  def get_session(id, context, options \\ []), do: get(id, context, options)

  def create(session, context, options \\ [])

  # An already-built %UserSession{} struct (or changeset) is handed straight to
  # the framework create (super -> Noizu.Repo.Meta.create). Routing a struct
  # through change/2 would Enum.map over the struct and raise `Enumerable not
  # implemented for GottaCc.Users.Sessions.UserSession`. The attrs-map clause
  # keeps the change/2 build path.
  def create(%Ecto.Changeset{} = changeset, context, options),
    do: super(changeset, context, options)

  def create(%Entity{} = session, context, options), do: super(session, context, options)

  def create(attrs, context, options) do
    %Entity{}
    |> change(attrs)
    |> super(context, options)
  end

  def delete(session, context, options \\ []) do
    super(session, context, options)
  end

  def change(%Entity{} = session, attrs \\ %{}) do
    attrs =
      Enum.map(
        attrs,
        fn
          {"user", value} -> {:user, value}
          {"credential", value} -> {:credential, value}
          {"status", value} -> {:status, String.to_existing_atom(value)}
          {"details", value} -> {:details, value}
          {"id", value} -> {:id, value}
          {x, value} when is_atom(x) -> {x, value}
          _ -> nil
        end
      )
      |> Enum.reject(&is_nil/1)

    Ecto.Changeset.change(
      {session, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]},
      attrs
    )
  end
end
