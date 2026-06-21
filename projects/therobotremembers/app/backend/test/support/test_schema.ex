defmodule TheRobotRemembers.TestSchema do
  @moduledoc """
  Applies the memory engine's schema (Liquibase changesets 025–030) to the test database.

  The canonical schema is Liquibase; `mix test` only runs the Ecto migrations (oban/smart_token).
  The memory tables are self-contained (they only FK to `memories`), so we create them here via a
  direct (non-Sandbox) connection so the DDL persists across the per-test transactions. Idempotent.
  """

  @statements [
    "CREATE EXTENSION IF NOT EXISTS vector",
    "CREATE EXTENSION IF NOT EXISTS pg_trgm",
    "DROP TABLE IF EXISTS recall_log, memory_quarantine, memory_agent_state, memory_compartments, association_edges, memories CASCADE",
    "DROP TYPE IF EXISTS edge_type, memory_classification, memory_state, memory_content_type CASCADE",
    "CREATE TYPE memory_content_type AS ENUM ('episodic','semantic','procedural')",
    "CREATE TYPE memory_state AS ENUM ('active','consolidating','archived','quarantined','pruned')",
    "CREATE TYPE memory_classification AS ENUM ('open','restricted','sealed')",
    "CREATE TYPE edge_type AS ENUM ('semantic','emotional','temporal','causal','co_occurrence','synthetic','contextual','tangent')",
    """
    CREATE TABLE memories (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      owner_agent text NOT NULL, source_agent text NOT NULL DEFAULT 'external',
      organization_id uuid, project_id uuid,
      content text NOT NULL, context text, reflection text, tangent text, summary text,
      content_type memory_content_type NOT NULL DEFAULT 'episodic',
      emotional_embedding vector(7) NOT NULL,
      valence real NOT NULL, arousal real NOT NULL, dominance real NOT NULL,
      cortisol real NOT NULL, dopamine real NOT NULL, oxytocin real NOT NULL, serotonin real NOT NULL,
      frustration_index real NOT NULL DEFAULT 0.0, confidence text NOT NULL DEFAULT 'low',
      occurred_at timestamptz NOT NULL DEFAULT now(), time_of_day text, day_of_week smallint, season text,
      domain text, topic text, session_id uuid, turn integer, modality text,
      collaborators text[] NOT NULL DEFAULT '{}', environment jsonb NOT NULL DEFAULT '{}',
      state memory_state NOT NULL DEFAULT 'consolidating', decay_weight real NOT NULL DEFAULT 1.0,
      pinned boolean NOT NULL DEFAULT false, last_recalled_at timestamptz,
      last_reinforced_at timestamptz NOT NULL DEFAULT now(),
      recall_count integer NOT NULL DEFAULT 0, reinforcement_count integer NOT NULL DEFAULT 0,
      denforcement_count integer NOT NULL DEFAULT 0, consolidation_ids uuid[] NOT NULL DEFAULT '{}',
      pruned_at timestamptz, compartment text NOT NULL DEFAULT 'default',
      classification memory_classification NOT NULL DEFAULT 'open',
      salience real GENERATED ALWAYS AS (decay_weight * (0.6 + 0.4 * GREATEST(abs(valence), arousal))) STORED,
      embedding_model text, embedding_version integer NOT NULL DEFAULT 1, vectors_synced boolean NOT NULL DEFAULT false,
      inserted_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
    )
    """,
    "CREATE INDEX idx_memories_owner_active ON memories (owner_agent, compartment) WHERE state IN ('active','consolidating')",
    "CREATE INDEX idx_memories_content_trgm ON memories USING gin (content gin_trgm_ops)",
    "CREATE INDEX idx_memories_context_trgm ON memories USING gin (context gin_trgm_ops)",
    """
    CREATE TABLE association_edges (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      source_memory_id uuid NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
      target_memory_id uuid NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
      weight real NOT NULL DEFAULT 0.5 CHECK (weight >= 0.0 AND weight <= 1.0),
      edge_type edge_type NOT NULL, created_by text NOT NULL DEFAULT 'weaver',
      reinforcement_count integer NOT NULL DEFAULT 0, denforcement_count integer NOT NULL DEFAULT 0,
      reason text, emotional_similarity real, temporal_proximity real,
      last_reinforced_at timestamptz NOT NULL DEFAULT now(),
      inserted_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
      CONSTRAINT uq_edge UNIQUE (source_memory_id, target_memory_id, edge_type),
      CONSTRAINT no_self_edge CHECK (source_memory_id <> target_memory_id)
    )
    """,
    "CREATE INDEX idx_edges_source_w ON association_edges (source_memory_id, weight DESC) WHERE weight >= 0.2",
    "CREATE INDEX idx_edges_target_w ON association_edges (target_memory_id, weight DESC) WHERE weight >= 0.2",
    """
    CREATE TABLE memory_compartments (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(), slug text NOT NULL, owner_agent text NOT NULL,
      classification memory_classification NOT NULL DEFAULT 'open', settings jsonb NOT NULL DEFAULT '{}',
      inserted_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
      CONSTRAINT uq_compartment UNIQUE (owner_agent, slug)
    )
    """,
    """
    CREATE TABLE memory_agent_state (
      agent_id text PRIMARY KEY, status text NOT NULL DEFAULT 'active',
      current_emotional vector(7), baseline_emotional vector(7), current_bucket text,
      last_bucket_refresh timestamptz, metrics jsonb NOT NULL DEFAULT '{}',
      inserted_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
    )
    """,
    """
    CREATE TABLE memory_quarantine (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(), memory_id uuid REFERENCES memories(id) ON DELETE SET NULL,
      owner_agent text NOT NULL, reason text NOT NULL, payload jsonb NOT NULL DEFAULT '{}',
      resolved boolean NOT NULL DEFAULT false,
      inserted_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
    )
    """,
    """
    CREATE TABLE recall_log (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(), requester_id text NOT NULL, owner_agent text NOT NULL,
      mode text NOT NULL, query text, total_candidates integer, returned_count integer,
      hot_index_hit boolean NOT NULL DEFAULT false, duration_ms integer,
      result_memory_ids uuid[] NOT NULL DEFAULT '{}', path_breakdown jsonb NOT NULL DEFAULT '{}',
      occurred_at timestamptz NOT NULL DEFAULT now()
    )
    """
  ]

  @doc "Create the memory schema in the test DB via a direct connection. Idempotent."
  def ensure_memory_schema! do
    cfg = TheRobotRemembers.Repo.config()

    {:ok, conn} =
      Postgrex.start_link(
        hostname: cfg[:hostname],
        port: cfg[:port] || 5432,
        username: cfg[:username],
        password: cfg[:password],
        database: cfg[:database],
        types: TheRobotRemembers.PostgrexTypes
      )

    try do
      Enum.each(@statements, fn sql -> Postgrex.query!(conn, sql, []) end)
    after
      GenServer.stop(conn)
    end

    :ok
  end
end
