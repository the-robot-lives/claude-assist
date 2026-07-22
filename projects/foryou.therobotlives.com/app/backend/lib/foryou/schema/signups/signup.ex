defmodule Foryou.Schema.Signups.Signup do
  @moduledoc """
  A person on a List. `email` is citext so `(list_id, email)` uniqueness is
  case-insensitive. `user_id` is null until reconcile-on-login links the signup
  to an account. `attribs` holds the typed attribute values (+ listmonk
  provenance under `attribs["listmonk"]`). `contact_prefs` / `pause_until` are
  per-signup contact preferences consumed by the Preference Center (D10).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending_optin subscribed unsubscribed bounced)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "signups" do
    belongs_to :list, Foryou.Schema.Lists.List, type: Ecto.UUID
    belongs_to :user, Foryou.Schema.Users.User, type: Ecto.UUID
    field :email, :string
    field :attribs, :map, default: %{}
    field :contact_prefs, :map, default: %{}
    field :pause_until, :utc_datetime_usec
    field :status, :string, default: "pending_optin"
    field :confirm_token, :string
    field :confirm_sent_at, :utc_datetime_usec
    field :unsub_token, :string
    field :source, :string
    field :submitter_ip, :string
    timestamps(type: :utc_datetime_usec, inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def changeset(signup, attrs) do
    signup
    |> cast(attrs, [:list_id, :email, :user_id, :attribs, :contact_prefs, :pause_until,
                    :status, :confirm_token, :confirm_sent_at, :unsub_token,
                    :source, :submitter_ip])
    |> validate_required([:list_id, :email, :unsub_token])
    |> normalize_email()
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:email, name: :uq_signups_list_email)
    |> foreign_key_constraint(:list_id)
    |> foreign_key_constraint(:user_id)
  end

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, email |> String.trim() |> String.downcase())
    end
  end
end
