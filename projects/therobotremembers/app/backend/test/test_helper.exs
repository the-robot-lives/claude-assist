ExUnit.start()
# Apply the memory engine schema (Liquibase 025–030) to the test DB. Canonical schema is
# Liquibase; this keeps the memory suite self-contained (the tables only FK to `memories`).
TheRobotRemembers.TestSchema.ensure_memory_schema!()

# Force external services off in tests (deterministic, no network): recall uses the pg_trgm
# lexical fallback + pgvector emotional path, never OpenAI/Weaviate, regardless of shell env.
Application.put_env(
  :the_robot_remembers,
  :embeddings,
  Keyword.put(Application.get_env(:the_robot_remembers, :embeddings, []), :api_key, nil)
)

Application.put_env(
  :the_robot_remembers,
  :weaviate,
  Keyword.put(Application.get_env(:the_robot_remembers, :weaviate, []), :enabled, false)
)

Ecto.Adapters.SQL.Sandbox.mode(TheRobotRemembers.Repo, :manual)
