defmodule HoloGraph.Docs do
  @moduledoc """
  Repo-backed persistence for HoloGraph UML documents.

  Backed by the changelog-026 tables:

    * `graph_documents` — one row per document; the canonical frontend
      `GraphDocument` payload is stored verbatim in the `document` jsonb column
      and `current_version` is the authoritative version counter.
    * `collab_events` — the append-only patch-batch log, de-duplicated on
      `client_event_id`.
    * `graph_document_versions` — full-document snapshots, written on every
      explicit save/restore and on every Nth patch batch (see
      `snapshot_every/0`).

  Envelope validation and sanitization live in `HoloGraph.Docs.Document`; the
  patch-batch wire protocol lives in `HoloGraph.Docs.PatchBatch`. Disk fixtures
  are a seed/import path only — see `HoloGraph.Docs.Fixtures`.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias HoloGraph.Docs.Document
  alias HoloGraph.Docs.Fixtures
  alias HoloGraph.Docs.PatchBatch
  alias HoloGraph.Repo
  alias HoloGraph.Schema.Docs.CollabEvent
  alias HoloGraph.Schema.Docs.GraphDocument, as: DocSchema
  alias HoloGraph.Schema.Docs.GraphDocumentVersion

  @snapshot_every 20
  @max_slug_attempts 50

  @type doc :: DocSchema.t()
  @type error ::
          :not_found
          | {:invalid_document, [String.t()]}
          | {:invalid_patch_batch, [String.t()]}
          | {:version_conflict, map()}
          | Ecto.Changeset.t()

  @doc "Number of patch batches between automatic full-document snapshots."
  @spec snapshot_every() :: pos_integer()
  def snapshot_every, do: @snapshot_every

  # -- create --------------------------------------------------------------

  @doc """
  Creates a document from a canonical `GraphDocument` payload.

  Attrs: `:document` (required), `:project_id`, `:organization_id`, `:title`,
  `:slug`, `:summary`, `:status`, `:metadata`, `:actor_user_id`.

  The persisted payload is stamped so its `id`/`version`/`updatedAt` envelope
  matches the database row.
  """
  @spec create_document(map()) :: {:ok, doc()} | {:error, error()}
  def create_document(attrs) when is_map(attrs) do
    attrs = Document.stringify(attrs)

    with {:ok, payload} <- Document.validate_and_normalize(Map.get(attrs, "document")) do
      now = DateTime.utc_now()
      id = Ecto.UUID.generate()
      title = string_attr(attrs, "title") || Map.get(payload, "title")
      slug = unique_slug(string_attr(attrs, "slug") || Map.get(payload, "slug") || title)

      payload =
        payload
        |> Map.put("id", id)
        |> Map.put("slug", slug)
        |> Map.put("title", title)
        |> Document.stamp(1, now)

      record_attrs = %{
        organization_id: Map.get(attrs, "organization_id"),
        project_id: Map.get(attrs, "project_id"),
        slug: slug,
        title: title,
        summary: string_attr(attrs, "summary") || Map.get(payload, "summary"),
        status: string_attr(attrs, "status") || "active",
        current_version: 1,
        document: payload,
        metadata: Map.get(attrs, "metadata") || %{}
      }

      Multi.new()
      |> Multi.insert(:document, DocSchema.changeset(%DocSchema{id: id}, record_attrs))
      |> Multi.insert(:version, fn %{document: document} ->
        snapshot_changeset(document, %{"kind" => "create"}, Map.get(attrs, "actor_user_id"), %{})
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{document: document}} -> {:ok, document}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  # -- read ----------------------------------------------------------------

  @doc """
  Fetches a document by database uuid or slug.
  """
  @spec get_document(String.t()) :: {:ok, doc()} | {:error, :not_found}
  def get_document(id_or_slug) when is_binary(id_or_slug) do
    query =
      case Ecto.UUID.cast(id_or_slug) do
        {:ok, uuid} -> from(d in DocSchema, where: d.id == ^uuid or d.slug == ^id_or_slug)
        :error -> from(d in DocSchema, where: d.slug == ^id_or_slug)
      end

    case Repo.one(from(d in query, limit: 1)) do
      nil -> {:error, :not_found}
      document -> {:ok, document}
    end
  end

  def get_document(_id_or_slug), do: {:error, :not_found}

  @doc """
  Lists summary rows for a project's documents, newest first.

  Options: `:status` (defaults to everything except `"deleted"`), `:limit`.
  """
  @spec list_by_project(String.t(), keyword()) :: [map()]
  def list_by_project(project_id, opts \\ []) when is_binary(project_id) do
    query =
      from(d in DocSchema,
        where: d.project_id == ^project_id,
        order_by: [desc: d.updated_at]
      )

    query =
      case Keyword.get(opts, :status) do
        nil -> from(d in query, where: d.status != "deleted")
        status -> from(d in query, where: d.status == ^status)
      end

    query =
      case Keyword.get(opts, :limit) do
        nil -> query
        limit -> from(d in query, limit: ^limit)
      end

    query
    |> Repo.all()
    |> Enum.map(&summary/1)
  end

  @doc """
  Summary row for a persisted document (database values win over the jsonb
  envelope).
  """
  @spec summary(doc()) :: map()
  def summary(%DocSchema{} = document) do
    document.document
    |> Document.summary()
    |> Map.merge(%{
      id: document.id,
      slug: document.slug,
      title: document.title,
      summary: document.summary,
      status: document.status,
      version: document.current_version,
      updatedAt: document.updated_at,
      insertedAt: document.inserted_at,
      projectId: document.project_id,
      organizationId: document.organization_id
    })
  end

  # -- update --------------------------------------------------------------

  @doc """
  Full-document save.

  Options: `:expected_version` (optimistic lock — `{:error, {:version_conflict,
  _}}` when it does not match `current_version`), `:actor_user_id`.

  Always writes a `graph_document_versions` snapshot.
  """
  @spec update_document(String.t(), map(), keyword()) :: {:ok, doc()} | {:error, error()}
  def update_document(id, attrs, opts \\ []) when is_map(attrs) do
    attrs = Document.stringify(attrs)

    Repo.transaction(fn ->
      with {:ok, record} <- lock_document(id),
           :ok <- check_version(record, Keyword.get(opts, :expected_version)),
           {:ok, payload} <- resolve_payload(record, Map.get(attrs, "document")) do
        now = DateTime.utc_now()
        next_version = record.current_version + 1
        title = string_attr(attrs, "title") || Map.get(payload, "title") || record.title
        slug = resolve_slug(record, attrs, payload)

        payload =
          payload
          |> Map.put("id", record.id)
          |> Map.put("slug", slug)
          |> Map.put("title", title)
          |> Document.stamp(next_version, now)

        record_attrs = %{
          slug: slug,
          title: title,
          summary: string_attr(attrs, "summary") || record.summary,
          status: string_attr(attrs, "status") || record.status,
          current_version: next_version,
          document: payload,
          metadata: Map.get(attrs, "metadata") || record.metadata
        }

        updated = insert_or_rollback(DocSchema.changeset(record, record_attrs), :update)

        insert_or_rollback(
          snapshot_changeset(
            updated,
            Map.get(attrs, "patch") || %{"kind" => "full_save"},
            Keyword.get(opts, :actor_user_id),
            Map.get(attrs, "version_metadata") || %{}
          ),
          :insert
        )

        updated
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  # -- patch batches -------------------------------------------------------

  @doc """
  Applies a patch batch: logs it verbatim to `collab_events`, bumps
  `current_version`, and snapshots every #{@snapshot_every}th version.

  Batches carrying a `document` payload replace the stored document; batches
  without one advance the version and event log only.

  Returns `{:ok, %{document:, version:, deduplicated?:, snapshot?:}}`. Replaying
  a batch with a `client_event_id` already seen for the document is a no-op that
  reports the original version.
  """
  @spec apply_patch_batch(String.t(), map(), keyword()) :: {:ok, map()} | {:error, error()}
  def apply_patch_batch(id, batch_input, opts \\ []) do
    with {:ok, batch} <- PatchBatch.parse(batch_input) do
      Repo.transaction(fn ->
        with {:ok, record} <- lock_document(id),
             :no_duplicate <- find_duplicate(record, batch),
             :ok <- check_version(record, batch.base_version) do
          now = DateTime.utc_now()
          next_version = record.current_version + 1
          payload = Document.stamp(batch.document || record.document, next_version, now)
          snapshot? = rem(next_version, @snapshot_every) == 0

          updated =
            insert_or_rollback(
              DocSchema.changeset(record, %{current_version: next_version, document: payload}),
              :update
            )

          insert_or_rollback(
            CollabEvent.changeset(%CollabEvent{}, %{
              graph_document_id: updated.id,
              actor_user_id: Keyword.get(opts, :actor_user_id),
              version: next_version,
              event_type: batch.event_type,
              client_event_id: batch.client_event_id,
              patch: PatchBatch.to_patch_payload(batch),
              metadata: batch.metadata
            }),
            :insert
          )

          if snapshot? do
            insert_or_rollback(
              snapshot_changeset(
                updated,
                PatchBatch.to_patch_payload(batch),
                Keyword.get(opts, :actor_user_id),
                %{"reason" => "patch_cadence"}
              ),
              :insert
            )
          end

          %{
            document: updated,
            version: next_version,
            deduplicated?: false,
            snapshot?: snapshot?
          }
        else
          {:duplicate, record, event} ->
            %{
              document: record,
              version: event.version || record.current_version,
              deduplicated?: true,
              snapshot?: false
            }

          {:error, reason} ->
            Repo.rollback(reason)
        end
      end)
    end
  end

  # -- versions ------------------------------------------------------------

  @doc """
  Version history for a document, newest first. Snapshots are omitted from the
  listing payload — use `get_version/2` for the full document.
  """
  @spec list_versions(String.t(), keyword()) :: {:ok, [map()]} | {:error, :not_found}
  def list_versions(id, opts \\ []) do
    with {:ok, record} <- get_document(id) do
      query =
        from(v in GraphDocumentVersion,
          where: v.graph_document_id == ^record.id,
          order_by: [desc: v.version]
        )

      query =
        case Keyword.get(opts, :limit) do
          nil -> query
          limit -> from(v in query, limit: ^limit)
        end

      versions =
        query
        |> Repo.all()
        |> Enum.map(fn version ->
          %{
            version: version.version,
            patch: version.patch,
            metadata: version.metadata,
            actorUserId: version.actor_user_id,
            insertedAt: version.inserted_at,
            nodeCount: length(list_or_empty(Map.get(version.document, "nodes"))),
            edgeCount: length(list_or_empty(Map.get(version.document, "edges")))
          }
        end)

      {:ok, versions}
    end
  end

  @doc "Fetches a single snapshot."
  @spec get_version(String.t(), integer()) ::
          {:ok, GraphDocumentVersion.t()} | {:error, :not_found}
  def get_version(id, version) do
    with {:ok, record} <- get_document(id),
         {:ok, version} <- cast_version(version) do
      case Repo.one(
             from(v in GraphDocumentVersion,
               where: v.graph_document_id == ^record.id and v.version == ^version
             )
           ) do
        nil -> {:error, :not_found}
        snapshot -> {:ok, snapshot}
      end
    end
  end

  @doc """
  Restores a snapshot as a new version (history is append-only — nothing is
  rewritten).
  """
  @spec restore_version(String.t(), integer(), keyword()) :: {:ok, doc()} | {:error, error()}
  def restore_version(id, version, opts \\ []) do
    with {:ok, snapshot} <- get_version(id, version) do
      update_document(
        id,
        %{
          "document" => snapshot.document,
          "patch" => %{"kind" => "restore", "restored_from_version" => snapshot.version},
          "version_metadata" => %{"restored_from_version" => snapshot.version}
        },
        Keyword.delete(opts, :expected_version)
      )
    end
  end

  # -- fixtures (seed/import path) -----------------------------------------

  @doc """
  Imports a disk fixture into the database. The fixture must be a canonical
  `GraphDocument` payload; legacy lanes/kanban fixtures are detected by their
  `lanes` key and rejected with `{:error, :legacy_fixture}` (they would
  otherwise sanitize down to an empty graph, since none of their node kinds are
  UML kinds).
  """
  @spec import_fixture(String.t(), map()) :: {:ok, doc()} | {:error, error() | :legacy_fixture}
  def import_fixture(fixture, attrs \\ %{})

  def import_fixture(fixture, attrs) when is_binary(fixture) and is_map(attrs) do
    with {:ok, payload} <- Fixtures.payload(fixture),
         :ok <- reject_legacy_fixture(payload) do
      attrs = Document.stringify(attrs)
      metadata = Map.merge(Map.get(attrs, "metadata") || %{}, %{"imported_from_fixture" => fixture})

      attrs
      |> Map.put("document", payload)
      |> Map.put("metadata", metadata)
      |> create_document()
    end
  end

  def import_fixture(_fixture, _attrs), do: {:error, :invalid_fixture}

  defp reject_legacy_fixture(payload) when is_map(payload) do
    if Map.has_key?(payload, "lanes"), do: {:error, :legacy_fixture}, else: :ok
  end

  defp reject_legacy_fixture(_payload), do: :ok

  # -- internals -----------------------------------------------------------

  defp lock_document(id) when is_binary(id) do
    query =
      case Ecto.UUID.cast(id) do
        {:ok, uuid} -> from(d in DocSchema, where: d.id == ^uuid or d.slug == ^id)
        :error -> from(d in DocSchema, where: d.slug == ^id)
      end

    case Repo.one(from(d in query, limit: 1, lock: "FOR UPDATE")) do
      nil -> {:error, :not_found}
      document -> {:ok, document}
    end
  end

  defp lock_document(_id), do: {:error, :not_found}

  defp check_version(_record, nil), do: :ok

  defp check_version(%DocSchema{current_version: current}, expected) when current == expected,
    do: :ok

  defp check_version(%DocSchema{} = record, expected) do
    {:error,
     {:version_conflict,
      %{
        expected_version: expected,
        current_version: record.current_version,
        document_id: record.id
      }}}
  end

  defp find_duplicate(_record, %PatchBatch{client_event_id: nil}), do: :no_duplicate

  defp find_duplicate(record, %PatchBatch{client_event_id: client_event_id}) do
    case Repo.one(
           from(e in CollabEvent,
             where:
               e.graph_document_id == ^record.id and e.client_event_id == ^client_event_id,
             limit: 1
           )
         ) do
      nil -> :no_duplicate
      event -> {:duplicate, record, event}
    end
  end

  defp resolve_payload(_record, nil), do: {:error, {:invalid_document, ["document is required"]}}
  defp resolve_payload(_record, payload), do: Document.validate_and_normalize(payload)

  defp resolve_slug(record, attrs, payload) do
    requested = string_attr(attrs, "slug") || Map.get(payload, "slug")

    cond do
      is_nil(requested) -> record.slug
      String.downcase(requested) == String.downcase(record.slug) -> record.slug
      true -> unique_slug(requested, record.id)
    end
  end

  defp snapshot_changeset(%DocSchema{} = document, patch, actor_user_id, metadata) do
    GraphDocumentVersion.changeset(%GraphDocumentVersion{}, %{
      graph_document_id: document.id,
      actor_user_id: actor_user_id,
      version: document.current_version,
      document: document.document,
      patch: patch || %{},
      metadata: metadata || %{}
    })
  end

  defp insert_or_rollback(changeset, :insert) do
    case Repo.insert(changeset) do
      {:ok, record} -> record
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp insert_or_rollback(changeset, :update) do
    case Repo.update(changeset) do
      {:ok, record} -> record
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp unique_slug(base, exclude_id \\ nil) do
    base = Document.slugify(base)

    Enum.reduce_while(1..@max_slug_attempts, nil, fn attempt, _acc ->
      candidate = if attempt == 1, do: base, else: "#{base}-#{attempt}"

      if slug_taken?(candidate, exclude_id) do
        {:cont, nil}
      else
        {:halt, candidate}
      end
    end) || "#{base}-#{System.unique_integer([:positive])}"
  end

  defp slug_taken?(candidate, exclude_id) do
    query = from(d in DocSchema, where: d.slug == ^candidate, select: d.id)
    query = if exclude_id, do: from(d in query, where: d.id != ^exclude_id), else: query

    Repo.exists?(query)
  end

  defp cast_version(version) when is_integer(version) and version > 0, do: {:ok, version}

  defp cast_version(version) when is_binary(version) do
    case Integer.parse(version) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, :not_found}
    end
  end

  defp cast_version(_version), do: {:error, :not_found}

  defp string_attr(attrs, key) do
    case Map.get(attrs, key) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []
end
