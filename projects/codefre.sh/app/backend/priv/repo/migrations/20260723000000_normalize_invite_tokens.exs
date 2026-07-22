defmodule Codefresh.Repo.Migrations.NormalizeInviteTokens do
  use Ecto.Migration

  def up do
    create_if_not_exists table(:invite_tokens) do
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all)
      add :email, :string
      add :role, :string, null: false, default: "viewer"
      add :token_hash, :binary, null: false
      add :key_prefix, :string, null: false
      add :max_uses, :integer, default: 1
      add :use_count, :integer, default: 0
      add :last_redeemed_at, :utc_datetime
      add :revoked_at, :utc_datetime
      add :metadata, :map, default: %{}
      add :invited_by_user_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    maybe_add_column(:invite_tokens, :organization_id, "uuid")
    maybe_add_column(:invite_tokens, :email, "text")
    maybe_add_column(:invite_tokens, :role, "text NOT NULL DEFAULT 'viewer'")
    maybe_add_column(:invite_tokens, :token_hash, "bytea")
    maybe_add_column(:invite_tokens, :key_prefix, "text")
    maybe_add_column(:invite_tokens, :expires_at, "timestamp(0) without time zone")
    maybe_add_column(:invite_tokens, :max_uses, "integer NOT NULL DEFAULT 1")
    maybe_add_column(:invite_tokens, :use_count, "integer NOT NULL DEFAULT 0")
    maybe_add_column(:invite_tokens, :last_redeemed_at, "timestamp(0) without time zone")
    maybe_add_column(:invite_tokens, :revoked_at, "timestamp(0) without time zone")
    maybe_add_column(:invite_tokens, :metadata, "jsonb NOT NULL DEFAULT '{}'::jsonb")
    maybe_add_column(:invite_tokens, :invited_by_user_id, "uuid")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'invite_tokens' AND column_name = 'uses'
      ) THEN
        EXECUTE 'UPDATE invite_tokens SET use_count = uses WHERE use_count = 0';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'invite_tokens' AND column_name = 'revoked'
      ) THEN
        EXECUTE 'UPDATE invite_tokens SET revoked_at = NOW() WHERE revoked_at IS NULL AND revoked = TRUE';
      END IF;
    END $$;
    """)

    create_if_not_exists unique_index(:invite_tokens, [:token_hash])
    create_if_not_exists index(:invite_tokens, [:organization_id])
    create_if_not_exists index(:invite_tokens, [:key_prefix])
  end

  def down do
    drop_if_exists index(:invite_tokens, [:key_prefix])
    drop_if_exists index(:invite_tokens, [:organization_id])
    drop_if_exists unique_index(:invite_tokens, [:token_hash])

    drop_if_exists table(:invite_tokens)
  end

  defp maybe_add_column(table, column, definition) do
    execute("""
    ALTER TABLE #{table}
    ADD COLUMN IF NOT EXISTS #{column} #{definition}
    """)
  end
end
