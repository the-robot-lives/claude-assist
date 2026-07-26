defmodule HoloGraphWeb.DocsController do
  use HoloGraphWeb, :controller

  alias HoloGraph.Authz
  alias HoloGraph.Docs
  alias HoloGraph.Docs.Fixtures
  alias HoloGraph.Docs.GraphDocument, as: FixtureDocument
  alias HoloGraph.Projects

  @view_action "project:view"
  @edit_action "project:update"

  # -- project-scoped collection ------------------------------------------

  def project_index(conn, %{"project_id" => project_id}) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "project", project_id, @view_action) do
      json(conn, %{
        data: Docs.list_by_project(project_id),
        meta: %{source: "database", projectId: project_id}
      })
    else
      forbidden(conn)
    end
  end

  def create(conn, %{"project_id" => project_id} = params) do
    user_id = get_user_id(conn)

    if Authz.check_permission(user_id, "project", project_id, @edit_action) do
      case Projects.get_project(project_id) do
        nil ->
          not_found(conn, "Project not found")

        project ->
          params
          |> Map.take(["document", "title", "slug", "summary", "status", "metadata"])
          |> Map.merge(%{
            "project_id" => project.id,
            "organization_id" => project.organization_id,
            "actor_user_id" => user_id
          })
          |> Docs.create_document()
          |> respond_document(conn, :created)
      end
    else
      forbidden(conn)
    end
  end

  # -- document-scoped ----------------------------------------------------

  def show(conn, %{"id" => id}) do
    with_document(conn, id, @view_action, fn conn, document ->
      json(conn, %{data: document.document, meta: document_meta(document)})
    end)
  end

  def update(conn, %{"id" => id} = params) do
    with_document(conn, id, @edit_action, fn conn, document ->
      attrs = Map.take(params, ["document", "title", "slug", "summary", "status", "metadata"])

      document.id
      |> Docs.update_document(attrs,
        expected_version: expected_version(params),
        actor_user_id: get_user_id(conn)
      )
      |> respond_document(conn, :ok)
    end)
  end

  def patches(conn, %{"id" => id} = params) do
    with_document(conn, id, @edit_action, fn conn, document ->
      batch = Map.drop(params, ["id"])

      case Docs.apply_patch_batch(document.id, batch, actor_user_id: get_user_id(conn)) do
        {:ok, result} ->
          json(conn, %{
            data: %{
              documentId: result.document.id,
              version: result.version,
              status: if(result.deduplicated?, do: "deduplicated", else: "applied"),
              clientEventId: params["client_event_id"] || params["clientEventId"],
              snapshot: result.snapshot?
            },
            meta: document_meta(result.document)
          })

        {:error, reason} ->
          error_response(conn, reason)
      end
    end)
  end

  def versions(conn, %{"id" => id}) do
    with_document(conn, id, @view_action, fn conn, document ->
      {:ok, versions} = Docs.list_versions(document.id)
      json(conn, %{data: versions, meta: document_meta(document)})
    end)
  end

  def restore(conn, %{"id" => id, "version" => version}) do
    with_document(conn, id, @edit_action, fn conn, document ->
      document.id
      |> Docs.restore_version(version, actor_user_id: get_user_id(conn))
      |> respond_document(conn, :ok)
    end)
  end

  # -- fixtures (seed/import path) ----------------------------------------

  def fixture_index(conn, _params) do
    json(conn, %{data: Fixtures.list_summaries(), meta: %{source: "fixture"}})
  end

  def fixture_show(conn, %{"id" => id}) do
    case Fixtures.get_document(id) do
      {:ok, document} ->
        json(conn, %{data: FixtureDocument.to_map(document), meta: %{source: "fixture"}})

      {:error, :not_found} ->
        not_found(conn, "Document not found")
    end
  end

  @doc """
  Admin-gated fixture import.

  Canonical `GraphDocument` fixtures are persisted; legacy lanes/kanban fixtures
  are echoed back unpersisted so the pre-existing contract keeps working.
  """
  def import_fixture(conn, params) do
    fixture = params["fixture"] || params["slug"] || params["id"]

    attrs =
      params
      |> Map.take(["project_id", "organization_id", "title", "slug", "summary", "metadata"])
      |> Map.put("actor_user_id", get_user_id(conn))

    case Docs.import_fixture(fixture, attrs) do
      {:ok, document} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: document.document,
          meta: Map.merge(document_meta(document), %{imported: true, source: "fixture"})
        })

      {:error, :legacy_fixture} ->
        legacy_import_fixture(conn, fixture, params)

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  defp legacy_import_fixture(conn, fixture, params) do
    case Fixtures.legacy_import(fixture, params) do
      {:ok, document} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: FixtureDocument.to_map(document),
          meta: %{imported: true, persisted: false, source: "fixture"}
        })

      {:error, reason} ->
        error_response(conn, reason)
    end
  end

  # -- shared -------------------------------------------------------------

  defp with_document(conn, id, action, fun) do
    case Docs.get_document(id) do
      {:error, :not_found} ->
        not_found(conn, "Document not found")

      {:ok, document} ->
        if authorized?(conn, document, action) do
          fun.(conn, document)
        else
          forbidden(conn)
        end
    end
  end

  # Docs inherit the authorization of the project they hang off; org-scoped docs
  # fall back to the organization, and unscoped docs are platform-admin only.
  defp authorized?(conn, document, action) do
    user_id = get_user_id(conn)

    cond do
      is_nil(user_id) -> false
      document.project_id -> Authz.check_permission(user_id, "project", document.project_id, action)
      document.organization_id -> org_authorized?(user_id, document.organization_id, action)
      true -> platform_admin?(user_id)
    end
  end

  defp org_authorized?(user_id, organization_id, action) do
    action = String.replace_prefix(action, "project:", "organization:")
    Authz.check_permission(user_id, "organization", organization_id, action)
  end

  defp platform_admin?(user_id) do
    case HoloGraph.Repo.get(HoloGraph.Schema.Users.User, user_id) do
      nil -> false
      user -> Map.get(user, :admin, false) == true
    end
  end

  defp respond_document({:ok, document}, conn, status) do
    conn
    |> put_status(status)
    |> json(%{data: document.document, meta: document_meta(document)})
  end

  defp respond_document({:error, reason}, conn, _status), do: error_response(conn, reason)

  defp document_meta(document) do
    %{
      source: "database",
      documentId: document.id,
      projectId: document.project_id,
      organizationId: document.organization_id,
      currentVersion: document.current_version,
      status: document.status,
      updatedAt: document.updated_at
    }
  end

  defp expected_version(params) do
    case params["expected_version"] || params["expectedVersion"] || params["version"] ||
           get_in(params, ["document", "version"]) do
      version when is_integer(version) and version > 0 ->
        version

      version when is_binary(version) ->
        case Integer.parse(version) do
          {parsed, ""} when parsed > 0 -> parsed
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp error_response(conn, {:version_conflict, details}) do
    conn
    |> put_status(:conflict)
    |> json(%{
      error: %{
        code: "version_conflict",
        message: "Document has been modified since the version you based this save on",
        expected_version: details[:expected_version],
        current_version: details[:current_version]
      }
    })
  end

  defp error_response(conn, {:invalid_document, reasons}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{code: "invalid_document", message: "Invalid document", details: reasons}})
  end

  defp error_response(conn, {:invalid_patch_batch, reasons}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: %{code: "invalid_patch_batch", message: "Invalid patch batch", details: reasons}
    })
  end

  defp error_response(conn, :not_found), do: not_found(conn, "Document not found")

  defp error_response(conn, :invalid_fixture) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{code: "bad_request", message: "Invalid fixture"}})
  end

  defp error_response(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{code: "invalid_document", details: format_errors(changeset)}})
  end

  defp error_response(conn, reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{code: "invalid_document", message: inspect(reason)}})
  end

  defp not_found(conn, message) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "not_found", message: message}})
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: %{code: "forbidden", message: "Insufficient permissions"}})
  end

  defp get_user_id(conn) do
    case HoloGraph.Guardian.Plug.current_resource(conn) do
      %HoloGraph.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %HoloGraph.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
