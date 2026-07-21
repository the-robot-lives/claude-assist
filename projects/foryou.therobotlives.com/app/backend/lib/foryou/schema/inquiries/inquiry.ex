defmodule Foryou.Schema.Inquiries.Inquiry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "inquiries" do
    field :name, :string
    field :email, :string
    field :message, :string
    field :source, :string, default: "unknown"
    field :page_url, :string
    field :metadata, :map, default: %{}
    field :status, :string, default: "new"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(inquiry, attrs) do
    inquiry
    |> cast(attrs, [:name, :email, :message, :source, :page_url, :metadata, :status])
    |> normalize_email()
    |> validate_required([:name, :email, :message, :source])
    |> validate_length(:name, max: 255)
    |> validate_length(:email, max: 320)
    |> validate_length(:message, min: 1, max: 10_000)
    |> validate_length(:source, max: 120)
    |> validate_length(:page_url, max: 2_048)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must be a valid email")
    |> validate_format(:page_url, ~r/^https?:\/\//, message: "must be an http or https URL")
    |> validate_inclusion(:status, ["new", "reviewed", "closed", "spam"])
  end

  defp normalize_email(changeset) do
    update_change(changeset, :email, fn email ->
      email
      |> to_string()
      |> String.trim()
      |> String.downcase()
    end)
  end
end
