defmodule Therobotknows.Schema.Session.PlaySession do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "play_sessions" do
    field :title, :string, default: "Session"
    field :notes, :string, default: ""
    field :status, :string, default: "active"
    field :created_by, Ecto.UUID

    belongs_to :universe, Therobotknows.Schema.Universe.Universe
    has_many :log_entries, Therobotknows.Schema.Session.LogEntry, foreign_key: :session_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(s, attrs) do
    s
    |> cast(attrs, [:universe_id, :title, :notes, :status, :created_by])
    |> validate_required([:universe_id, :title])
    |> validate_inclusion(:status, ~w(active closed))
  end
end
