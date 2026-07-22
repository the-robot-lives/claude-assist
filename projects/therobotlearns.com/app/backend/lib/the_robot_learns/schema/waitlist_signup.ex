defmodule TheRobotLearns.Schema.WaitlistSignup do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(waitlist invited)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "waitlist_signups" do
    field :email, :string
    field :invite_token, :string
    field :focus, :string
    field :status, :string, default: "waitlist"
    field :source, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(signup, attrs) do
    signup
    |> cast(attrs, [:email, :invite_token, :focus, :status, :source])
    |> validate_required([:email, :focus, :status])
    |> validate_length(:focus, max: 64)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:email, name: :idx_waitlist_signups_email)
  end
end
