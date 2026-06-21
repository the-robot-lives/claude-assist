defmodule TheRobotRemembers.Schema.Memory.Memory do
  @moduledoc """
  A memory: four agent-authored texts (content/context/reflection/tangent), the
  pre-weighted 7-d emotional vector (agent VAD ++ Monitor hormone snapshot), contextual
  metadata, lifecycle, and access control. The four 1536-d text vectors live in Weaviate
  (keyed by this row's id); this row is the system of record for everything else.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "memories" do
    field :owner_agent, :string
    field :source_agent, :string, default: "external"
    field :organization_id, Ecto.UUID
    field :project_id, Ecto.UUID

    # Four texts
    field :content, :string
    field :context, :string
    field :reflection, :string
    field :tangent, :string
    field :summary, :string
    field :content_type, Ecto.Enum, values: [:episodic, :semantic, :procedural], default: :episodic

    # Emotional vector + raw components
    field :emotional_embedding, Pgvector.Ecto.Vector
    field :valence, :float
    field :arousal, :float
    field :dominance, :float
    field :cortisol, :float
    field :dopamine, :float
    field :oxytocin, :float
    field :serotonin, :float
    field :frustration_index, :float, default: 0.0
    field :confidence, :string, default: "low"

    # Contextual metadata
    field :occurred_at, :utc_datetime_usec
    field :time_of_day, :string
    field :day_of_week, :integer
    field :season, :string
    field :domain, :string
    field :topic, :string
    field :session_id, Ecto.UUID
    field :turn, :integer
    field :modality, :string
    field :collaborators, {:array, :string}, default: []
    field :environment, :map, default: %{}

    # Lifecycle
    field :state, Ecto.Enum,
      values: [:active, :consolidating, :archived, :quarantined, :pruned],
      default: :consolidating

    field :decay_weight, :float, default: 1.0
    field :pinned, :boolean, default: false
    field :last_recalled_at, :utc_datetime_usec
    field :last_reinforced_at, :utc_datetime_usec
    field :recall_count, :integer, default: 0
    field :reinforcement_count, :integer, default: 0
    field :denforcement_count, :integer, default: 0
    field :consolidation_ids, {:array, Ecto.UUID}, default: []
    field :pruned_at, :utc_datetime_usec

    # Access control
    field :compartment, :string, default: "default"
    field :classification, Ecto.Enum, values: [:open, :restricted, :sealed], default: :open

    # Read-only generated column
    field :salience, :float, read_after_writes: true

    # Embedding provenance
    field :embedding_model, :string
    field :embedding_version, :integer, default: 1
    field :vectors_synced, :boolean, default: false

    timestamps(type: :utc_datetime_usec)
  end

  @required ~w(owner_agent content emotional_embedding valence arousal dominance
               cortisol dopamine oxytocin serotonin)a
  @optional ~w(source_agent organization_id project_id context reflection tangent summary
               content_type frustration_index confidence occurred_at time_of_day day_of_week
               season domain topic session_id turn modality collaborators environment state
               decay_weight pinned last_recalled_at last_reinforced_at recall_count
               reinforcement_count denforcement_count consolidation_ids pruned_at compartment
               classification embedding_model embedding_version vectors_synced)a

  def changeset(memory, attrs) do
    memory
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:confidence, ["high", "medium", "low"])
    |> validate_number(:valence, greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0)
  end
end
