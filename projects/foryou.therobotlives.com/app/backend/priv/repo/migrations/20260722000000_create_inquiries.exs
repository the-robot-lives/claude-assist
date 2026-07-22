defmodule Foryou.Repo.Migrations.CreateInquiries do
  use Ecto.Migration

  def change do
    create table(:inquiries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :message, :text, null: false
      add :source, :string, null: false, default: "unknown"
      add :page_url, :string
      add :metadata, :map, null: false, default: %{}
      add :status, :string, null: false, default: "new"

      timestamps(type: :utc_datetime_usec)
    end

    create index(:inquiries, [:source, :inserted_at])
    create index(:inquiries, [:email])
    create index(:inquiries, [:status])
  end
end
