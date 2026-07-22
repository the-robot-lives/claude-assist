defmodule Foryou.Schema.Forms.FormSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "form_submissions" do
    belongs_to :form, Foryou.Schema.Forms.Form, type: Ecto.UUID
    field :form_version_id, Ecto.UUID
    field :payload, :map, default: %{}
    field :source, :string
    field :submitter_email, :string
    field :submitter_ip, :string
    field :status, :string, default: "new"
    # immutable — no updated_at column
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:form_id, :form_version_id, :payload, :source,
                    :submitter_email, :submitter_ip, :status])
    |> validate_required([:form_id, :payload])
  end
end
