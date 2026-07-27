defmodule Timely.Schema.Tracking.TimeSpan do
  @moduledoc """
  An interval of tracked work. Timely models time as overlapping intervals, not
  one linear stopwatch, so two live spans covering the same instant are legal
  and expected (conflict matrix row 8).

  `start_at` / `end_at` carry the wire fields `start` / `end`; the SQL words are
  reserved. `canonical_title` is maintained alongside `title` because suspected
  duplicate detection compares `canon(title_a) == canon(title_b)`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "time_spans" do
    field(:title, :string, default: "")
    field(:canonical_title, :string, default: "")
    field(:client_id, Ecto.UUID)
    field(:project_id, Ecto.UUID)
    field(:ticket_id, Ecto.UUID)
    field(:client_name, :string, default: "")
    field(:project_name, :string, default: "")
    field(:ticket_name, :string, default: "")
    field(:start_at, :utc_datetime_usec)
    field(:end_at, :utc_datetime_usec)
    field(:source, :string, default: "manual")
    field(:is_billable, :boolean, default: false)
    field(:notes, :string, default: "")
    field(:review_state, :string, default: "unreviewed")
    field(:review_reasons, {:array, :map}, default: [])
    field(:derived_from_span_ids, {:array, Ecto.UUID}, default: [])
    field(:locked_at, :utc_datetime_usec)
    field(:unresolved_refs, {:array, :string}, default: [])

    use Timely.Schema.Sync.Envelope
  end

  @castable [
    :id,
    :title,
    :canonical_title,
    :client_id,
    :project_id,
    :ticket_id,
    :client_name,
    :project_name,
    :ticket_name,
    :start_at,
    :end_at,
    :source,
    :is_billable,
    :notes,
    :review_state,
    :review_reasons,
    :derived_from_span_ids,
    :locked_at,
    :unresolved_refs
  ]

  # ⟦𓋴𓊪𓄿𓈖⟧ changeset :: TimeSpan changeset.
  def changeset(record, attrs) do
    record
    |> cast(attrs, @castable ++ Timely.Schema.Sync.Envelope.fields())
    |> validate_required([:id, :workspace_id, :start_at, :server_revision])
    |> validate_length(:title, max: 500)
    |> validate_inclusion(:source, Timely.Sync.Vocabulary.span_sources())
    |> validate_inclusion(:review_state, Timely.Sync.Vocabulary.review_states())
    |> validate_interval()
  end

  defp validate_interval(changeset) do
    start_at = get_field(changeset, :start_at)
    end_at = get_field(changeset, :end_at)

    if start_at && end_at && DateTime.compare(end_at, start_at) == :lt do
      add_error(changeset, :end_at, "must not precede start")
    else
      changeset
    end
  end
end
