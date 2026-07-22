defmodule Codefresh.Repo.Migrations.NoopAutoFlagRulesDuplicate do
  use Ecto.Migration

  # The 20260421000033 migration already creates this table with the same
  # structure. Keep this timestamp as a no-op so existing migration order stays
  # stable without replaying duplicate DDL.
  def change, do: :ok
end
