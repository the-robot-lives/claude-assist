defmodule Therobotsdayjob.Users.Sessions do
  @moduledoc """
  Context for Therobotsdayjob.Users.Sessions
  """
  alias Therobotsdayjob.Users.Sessions.UserSession, as: Entity
  alias Therobotsdayjob.Schema.Users.Sessions.UserSession, as: Schema
  use Noizu.Repo
  def_repo(entity: Therobotsdayjob.Users.Sessions.UserSession)

  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Therobotsdayjob.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  def get_session(id, context, options \\ []), do: get(id, context, options)

  def create(session, context, options \\ []) do
    %Entity{}
    |> change(session)
    |> super(context, options)
  end

  def delete(session, context, options \\ []) do
    super(session, context, options)
  end

  def change(%Entity{} = session, attrs \\ %{}) do
    changeset_fields = Noizu.Entity.Meta.meta(Entity)[:changeset_fields]

    attrs =
      attrs
      |> normalize_attrs()
      |> Enum.map(fn
        {"user", value} -> {:user, value}
        {"credential", value} -> {:credential, value}
        {"status", value} when is_binary(value) -> {:status, String.to_existing_atom(value)}
        {"details", value} -> {:details, value}
        {"id", value} -> {:id, value}
        {x, value} when is_atom(x) -> {x, value}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(fn {k, _} -> Map.has_key?(changeset_fields, k) end)

    Ecto.Changeset.change(
      {session, changeset_fields},
      Map.new(attrs)
    )
  end

  # Accept either a plain map (string/atom keys) or an %Entity{} struct as the
  # change source; structs carry framework fields (vsn/meta/__transient__) that
  # are not changeset fields, so drop them here.
  defp normalize_attrs(%Entity{} = attrs),
    do: attrs |> Map.from_struct() |> Map.drop([:__transient__, :meta, :vsn])

  defp normalize_attrs(attrs) when is_map(attrs), do: attrs
end
