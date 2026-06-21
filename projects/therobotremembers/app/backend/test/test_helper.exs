ExUnit.start()
# Apply the memory engine schema (Liquibase 025–030) to the test DB. Canonical schema is
# Liquibase; this keeps the memory suite self-contained (the tables only FK to `memories`).
TheRobotRemembers.TestSchema.ensure_memory_schema!()
Ecto.Adapters.SQL.Sandbox.mode(TheRobotRemembers.Repo, :manual)
