defmodule Therobotplans.Schema.RecurrenceRule do
  @moduledoc """
  A simplified RFC-5545-flavored recurrence rule (WS-A US-011). Enough of the
  spec to compile the six personal-todo presets (daily / weekdays / weekly /
  biweekly / monthly) plus `custom`. The anchor is the linked item's `due_date`;
  the rule stores only the recurrence shape, its owner, and its timezone.

  `freq` is one of `daily | weekly | monthly`; `weekdays`/`biweekly`/`weekly`
  all resolve onto `weekly` via `by_day`/`interval`. `until` XOR `count` (or
  neither = open-ended) — validated here, not in the DB.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @freqs ~w(daily weekly monthly)
  @day_codes ~w(MO TU WE TH FR SA SU)

  schema "recurrence_rules" do
    field :owner_user_id, :binary_id
    field :freq, :string
    field :interval, :integer, default: 1
    field :by_day, {:array, :string}, default: []
    field :by_month_day, {:array, :integer}, default: []
    field :until, :date
    field :count, :integer
    field :timezone, :string, default: "Etc/UTC"
    # Habits (US-012) opt-in: a nightly sweep advances an untouched overdue
    # occurrence instead of leaving it stale. Default false for plain todos.
    field :roll_on_skip, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :owner_user_id,
      :freq,
      :interval,
      :by_day,
      :by_month_day,
      :until,
      :count,
      :timezone,
      :roll_on_skip
    ])
    |> validate_required([:freq])
    |> validate_inclusion(:freq, @freqs)
    |> validate_number(:interval, greater_than: 0)
    |> validate_number(:count, greater_than: 0)
    |> validate_by_day()
    |> validate_until_xor_count()
    |> foreign_key_constraint(:owner_user_id)
  end

  defp validate_by_day(changeset) do
    case get_field(changeset, :by_day) do
      days when is_list(days) ->
        if Enum.all?(days, &(&1 in @day_codes)),
          do: changeset,
          else: add_error(changeset, :by_day, "must be two-letter day codes (MO..SU)")

      _ ->
        changeset
    end
  end

  # `until` and `count` are mutually exclusive; a rule bounds itself by an end
  # date OR an occurrence cap, never both.
  defp validate_until_xor_count(changeset) do
    if get_field(changeset, :until) && get_field(changeset, :count),
      do: add_error(changeset, :until, "cannot be set together with count"),
      else: changeset
  end

  def freqs, do: @freqs
  def day_codes, do: @day_codes
end
