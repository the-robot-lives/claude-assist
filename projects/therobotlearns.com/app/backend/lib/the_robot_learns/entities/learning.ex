defmodule TheRobotLearns.Learning do
  @moduledoc """
  Learning content owned by the cloud app (system of record): lesson plans,
  wiki pages, quizzes (+questions), references, decks (+cards). The REST
  surface doubles as the push/ingest API for the CLI and MCP connector.

  All types are project-scoped. Child types (quiz questions, deck cards) are
  scoped through their parent, which itself must belong to the project — this
  is what keeps the generic controller's PBAC check on the project valid.
  """
  import Ecto.Query, only: [from: 2]

  alias TheRobotLearns.Repo

  alias TheRobotLearns.Schema.Learning.{
    Deck,
    DeckCard,
    LessonPlan,
    Quiz,
    QuizQuestion,
    ReferenceEntry,
    WikiPage
  }

  @types %{
    "lesson-plans" => %{
      schema: LessonPlan,
      order_by: [asc: :position, asc: :inserted_at],
      fields: ~w(title body position status)
    },
    "wiki-pages" => %{
      schema: WikiPage,
      order_by: [desc: :updated_at],
      fields: ~w(title slug body)
    },
    "quizzes" => %{
      schema: Quiz,
      order_by: [asc: :inserted_at],
      fields: ~w(title description)
    },
    "references" => %{
      schema: ReferenceEntry,
      order_by: [asc: :inserted_at],
      fields: ~w(title url notes kind)
    },
    "decks" => %{
      schema: Deck,
      order_by: [asc: :inserted_at],
      fields: ~w(name description)
    },
    "quiz-questions" => %{
      schema: QuizQuestion,
      parent: %{key: "quiz_id", schema: Quiz},
      order_by: [asc: :position, asc: :inserted_at],
      fields: ~w(position prompt answer choices)
    },
    "deck-cards" => %{
      schema: DeckCard,
      parent: %{key: "deck_id", schema: Deck},
      order_by: [asc: :position, asc: :inserted_at],
      fields: ~w(position front back tags)
    }
  }

  def content_types, do: Map.keys(@types)

  def type_config(type), do: Map.fetch(@types, type)

  @doc "List records of `type` for a project (child types require parent_id)."
  def list(type, project_id, parent_id \\ nil) do
    with {:ok, config} <- type_config(type) do
      case config do
        %{parent: %{key: parent_key, schema: parent_schema}} ->
          with {:ok, _parent} <- fetch_parent_in_project(parent_schema, parent_id, project_id) do
            {:ok,
             Repo.all(
               from r in config.schema,
                 where: field(r, ^String.to_existing_atom(parent_key)) == ^parent_id,
                 order_by: ^config.order_by
             )}
          end

        _ ->
          {:ok,
           Repo.all(
             from r in config.schema,
               where: r.project_id == ^project_id,
               order_by: ^config.order_by
           )}
      end
    end
  end

  @doc "Create a record of `type` in a project. attrs uses string keys."
  def create(type, project_id, attrs, user_id \\ nil) do
    with {:ok, config} <- type_config(type),
         {:ok, scope} <- scope_attrs(config, project_id, attrs) do
      permitted = Map.take(attrs, config.fields) |> Map.merge(scope)
      permitted = if user_id, do: Map.put(permitted, "created_by", user_id), else: permitted

      struct(config.schema)
      |> config.schema.changeset(permitted)
      |> Repo.insert()
    end
  end

  @doc "Update a record by id, verifying it belongs to the project."
  def update(type, project_id, id, attrs) do
    with {:ok, config} <- type_config(type),
         {:ok, record} <- fetch_in_project(type, config, project_id, id) do
      record
      |> config.schema.changeset(Map.take(attrs, config.fields))
      |> Repo.update()
    end
  end

  @doc "Delete a record by id, verifying it belongs to the project."
  def delete(type, project_id, id) do
    with {:ok, config} <- type_config(type),
         {:ok, record} <- fetch_in_project(type, config, project_id, id) do
      Repo.delete(record)
    end
  end

  # ── internal ──────────────────────────────────────────────────────────

  defp scope_attrs(%{parent: %{key: parent_key, schema: parent_schema}}, project_id, attrs) do
    parent_id = attrs[parent_key]

    with {:ok, _parent} <- fetch_parent_in_project(parent_schema, parent_id, project_id) do
      {:ok, %{parent_key => parent_id}}
    end
  end

  defp scope_attrs(_config, project_id, _attrs), do: {:ok, %{"project_id" => project_id}}

  defp fetch_parent_in_project(_schema, nil, _project_id), do: {:error, :parent_required}

  defp fetch_parent_in_project(schema, parent_id, project_id) do
    case Repo.get(schema, parent_id) do
      %{project_id: ^project_id} = parent -> {:ok, parent}
      nil -> {:error, :parent_not_found}
      _ -> {:error, :parent_not_in_project}
    end
  end

  defp fetch_in_project(_type, %{parent: %{schema: parent_schema}} = config, project_id, id) do
    with %{} = record <- Repo.get(config.schema, id) || {:error, :not_found} do
      parent_id = record |> Map.from_struct() |> find_parent_id()

      case Repo.get(parent_schema, parent_id) do
        %{project_id: ^project_id} -> {:ok, record}
        _ -> {:error, :not_found}
      end
    end
  end

  defp fetch_in_project(_type, config, project_id, id) do
    case Repo.get(config.schema, id) do
      %{project_id: ^project_id} = record -> {:ok, record}
      nil -> {:error, :not_found}
      _ -> {:error, :not_found}
    end
  end

  defp find_parent_id(%{quiz_id: id}) when not is_nil(id), do: id
  defp find_parent_id(%{deck_id: id}) when not is_nil(id), do: id
  defp find_parent_id(_), do: nil
end
