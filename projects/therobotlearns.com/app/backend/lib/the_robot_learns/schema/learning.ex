defmodule TheRobotLearns.Schema.Learning.LessonPlan do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :project_id, :title, :body, :position, :status, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "lesson_plans" do
    field :project_id, Ecto.UUID
    field :title, :string
    field :body, :string
    field :position, :integer, default: 0
    field :status, :string, default: "draft"
    field :created_by, Ecto.UUID
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:project_id, :title, :body, :position, :status, :created_by])
    |> validate_required([:project_id, :title])
    |> validate_inclusion(:status, ~w(draft active completed archived))
  end
end

defmodule TheRobotLearns.Schema.Learning.WikiPage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :project_id, :title, :slug, :body, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "wiki_pages" do
    field :project_id, Ecto.UUID
    field :title, :string
    field :slug, :string
    field :body, :string
    field :created_by, Ecto.UUID
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:project_id, :title, :slug, :body, :created_by])
    |> validate_required([:project_id, :title])
    |> put_default_slug()
    |> unique_constraint([:project_id, :slug], name: :uq_wiki_pages_project_slug)
  end

  defp put_default_slug(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        title = get_field(changeset, :title) || ""

        slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9]+/, "-")
          |> String.trim("-")
          |> String.slice(0, 64)

        put_change(changeset, :slug, if(slug == "", do: Ecto.UUID.generate(), else: slug))

      _ ->
        changeset
    end
  end
end

defmodule TheRobotLearns.Schema.Learning.Quiz do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :project_id, :title, :description, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "quizzes" do
    field :project_id, Ecto.UUID
    field :title, :string
    field :description, :string
    field :created_by, Ecto.UUID
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:project_id, :title, :description, :created_by])
    |> validate_required([:project_id, :title])
  end
end

defmodule TheRobotLearns.Schema.Learning.QuizQuestion do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :quiz_id, :position, :prompt, :answer, :choices, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "quiz_questions" do
    field :quiz_id, Ecto.UUID
    field :position, :integer, default: 0
    field :prompt, :string
    field :answer, :string
    field :choices, {:array, :map}, default: []
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:quiz_id, :position, :prompt, :answer, :choices])
    |> validate_required([:quiz_id, :prompt])
  end
end

defmodule TheRobotLearns.Schema.Learning.ReferenceEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :project_id, :title, :url, :notes, :kind, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "reference_entries" do
    field :project_id, Ecto.UUID
    field :title, :string
    field :url, :string
    field :notes, :string
    field :kind, :string, default: "link"
    field :created_by, Ecto.UUID
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:project_id, :title, :url, :notes, :kind, :created_by])
    |> validate_required([:project_id, :title])
  end
end

defmodule TheRobotLearns.Schema.Learning.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :project_id, :name, :description, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "decks" do
    field :project_id, Ecto.UUID
    field :name, :string
    field :description, :string
    field :created_by, Ecto.UUID
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:project_id, :name, :description, :created_by])
    |> validate_required([:project_id, :name])
  end
end

defmodule TheRobotLearns.Schema.Learning.DeckCard do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:id, :deck_id, :position, :front, :back, :tags, :inserted_at, :updated_at]}
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "deck_cards" do
    field :deck_id, Ecto.UUID
    field :position, :integer, default: 0
    field :front, :string
    field :back, :string
    field :tags, {:array, :string}, default: []
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:deck_id, :position, :front, :back, :tags])
    |> validate_required([:deck_id, :front])
  end
end
