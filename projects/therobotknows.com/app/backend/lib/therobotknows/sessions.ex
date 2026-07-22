defmodule Therobotknows.Sessions do
  @moduledoc "GM session companion (M5.S5.6)."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Schema.Session.{PlaySession, LogEntry}

  def list(universe_id_or_slug, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      sessions =
        from(s in PlaySession,
          where: s.universe_id == ^universe.id,
          order_by: [desc: s.updated_at]
        )
        |> Repo.all()
        |> Enum.map(&session_map/1)

      {:ok, %{sessions: sessions}}
    end
  end

  def create(universe_id_or_slug, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor) do
      %PlaySession{}
      |> PlaySession.changeset(%{
        universe_id: universe.id,
        title: Map.get(attrs, "title") || Map.get(attrs, :title) || "Session",
        notes: Map.get(attrs, "notes") || Map.get(attrs, :notes) || "",
        created_by: user_id
      })
      |> Repo.insert()
      |> case do
        {:ok, s} -> {:ok, session_map(s)}
        e -> e
      end
    end
  end

  def get(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %PlaySession{} = s <- Repo.get_by(PlaySession, id: id, universe_id: universe.id) do
      logs =
        from(l in LogEntry, where: l.session_id == ^s.id, order_by: [asc: l.inserted_at])
        |> Repo.all()
        |> Enum.map(&log_map/1)

      {:ok, Map.put(session_map(s), :log_entries, logs)}
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def add_log(universe_id_or_slug, session_id, body, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %PlaySession{} = s <- Repo.get_by(PlaySession, id: session_id, universe_id: universe.id) do
      %LogEntry{}
      |> LogEntry.changeset(%{
        session_id: s.id,
        body: body,
        created_by: user_id,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })
      |> Repo.insert()
      |> case do
        {:ok, le} ->
          s
          |> PlaySession.changeset(%{})
          |> Ecto.Changeset.change(updated_at: DateTime.utc_now() |> DateTime.truncate(:microsecond))
          |> Repo.update()

          {:ok, log_map(le)}

        e ->
          e
      end
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def close(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %PlaySession{} = s <- Repo.get_by(PlaySession, id: id, universe_id: universe.id) do
      s
      |> PlaySession.changeset(%{status: "closed"})
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, session_map(updated)}
        e -> e
      end
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  defp session_map(%PlaySession{} = s) do
    %{
      id: s.id,
      universe_id: s.universe_id,
      title: s.title,
      notes: s.notes,
      status: s.status,
      created_by: s.created_by,
      inserted_at: s.inserted_at,
      updated_at: s.updated_at
    }
  end

  defp log_map(%LogEntry{} = l) do
    %{
      id: l.id,
      session_id: l.session_id,
      body: l.body,
      entry_id: l.entry_id,
      created_by: l.created_by,
      inserted_at: l.inserted_at
    }
  end
end
