defmodule Therobotknows.Schema.Session.LogEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "play_session_log_entries" do
    field :body, :string
    field :entry_id, Ecto.UUID
    field :created_by, Ecto.UUID
    field :inserted_at, :utc_datetime_usec

    belongs_to :session, Therobotknows.Schema.Session.PlaySession
  end

  def changeset(le, attrs) do
    le
    |> cast(attrs, [:session_id, :body, :entry_id, :created_by, :inserted_at])
    |> validate_required([:session_id, :body])
  end
end
