defmodule TherobotplansWeb.SavedViewController do
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.SavedViews
  alias Therobotplans.Schema.SavedView
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/saved-views
  #
  # Returns shared/org views (owner_user_id IS NULL) ∪ the caller's own views
  # within the (org, optional project) scope. Mirrors item_controller scoping.
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [organization_id: org_id]
        |> maybe_opt(:project_id, params["project_id"])
        |> maybe_opt(:view_type, params["view_type"])
        |> maybe_opt(:entity_type, params["entity_type"])

      views =
        SavedViews.list_views(
          org_id,
          opts[:project_id],
          user_id,
          Keyword.take(opts, [:view_type, :entity_type])
        )

      json(conn, %{saved_views: Enum.map(views, &view_to_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/saved-views
  def create(conn, %{"org_id" => org_id, "saved_view" => view_params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member"),
         {:ok, project_id} <- validate_project(view_params["project_id"], org_id) do
      attrs = %{
        organization_id: org_id,
        project_id: project_id,
        owner_user_id: view_params["owner_user_id"] || user_id,
        name: view_params["name"],
        entity_type: view_params["entity_type"] || "item",
        view_type: view_params["view_type"] || "list",
        config: view_params["config"] || %{},
        is_shared: cast_bool(view_params["is_shared"], false)
      }

      case SavedViews.create(attrs) do
        {:ok, view} ->
          conn |> put_status(:created) |> json(%{saved_view: view_to_json(view)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/saved-views/:id
  def show(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_view(conn, org_id, id, "viewer", fn view ->
      json(conn, %{saved_view: view_to_json(view)})
    end)
  end

  # PUT /api/v1/organizations/:org_id/saved-views/:id
  def update(conn, %{"org_id" => org_id, "id" => id, "saved_view" => attrs}) do
    with_org_view(conn, org_id, id, "member", fn view ->
      user_id = get_user_id(conn)

      if SavedViews.owned_or_shared?(view, user_id) do
        clean =
          Map.take(
            attrs,
            ~w(name entity_type view_type config is_shared project_id)
          )

        case SavedViews.update(view, clean) do
          {:ok, updated} ->
            json(conn, %{saved_view: view_to_json(updated)})

          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
        end
      else
        conn |> put_status(:forbidden) |> json(%{error: "Not the owner of this saved view"})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/saved-views/:id
  def delete(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_view(conn, org_id, id, "member", fn view ->
      user_id = get_user_id(conn)

      if SavedViews.owned_or_shared?(view, user_id) do
        case SavedViews.delete(view) do
          {:ok, _} -> conn |> put_status(:no_content) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to delete"})
        end
      else
        conn |> put_status(:forbidden) |> json(%{error: "Not the owner of this saved view"})
      end
    end)
  end

  # Resolve org, authorize, load the view, ensure it belongs to the org and is
  # visible to the caller (shared, or owned by them).
  defp with_org_view(conn, org_id, id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         %SavedView{} = view <- SavedViews.get(id),
         true <- view.organization_id == org_id,
         true <- SavedViews.owned_or_shared?(view, user_id) do
      fun.(view)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Saved view not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Saved view not found"})
      err -> handle_error(conn, err)
    end
  end

  defp view_to_json(v) do
    %{
      id: v.id,
      organization_id: v.organization_id,
      project_id: v.project_id,
      owner_user_id: v.owner_user_id,
      name: v.name,
      entity_type: v.entity_type,
      view_type: v.view_type,
      config: v.config,
      is_shared: v.is_shared,
      inserted_at: v.inserted_at,
      updated_at: v.updated_at
    }
  end

  defp cast_bool(true, _), do: true
  defp cast_bool(false, _), do: false
  defp cast_bool("true", _), do: true
  defp cast_bool("false", _), do: false
  defp cast_bool(_, default), do: default

  defp validate_project(nil, _org_id), do: {:ok, nil}
  defp validate_project("", _org_id), do: {:ok, nil}

  defp validate_project(project_id, org_id) do
    case Therobotplans.Projects.get_project(project_id) do
      nil -> {:error, :project_not_in_org}
      %{organization_id: ^org_id} -> {:ok, project_id}
      _ -> {:error, :project_not_in_org}
    end
  end

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Organization not found"})

      {:error, :not_a_member} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})

      {:error, :project_not_in_org} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Project does not belong to this organization"})

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp maybe_opt(opts, _key, nil), do: opts
  defp maybe_opt(opts, _key, ""), do: opts
  defp maybe_opt(opts, key, val), do: Keyword.put(opts, key, val)

  defp get_user_id(conn) do
    case Therobotplans.Guardian.Plug.current_resource(conn) do
      %Therobotplans.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotplans.Users.Sessions.UserSession{user: %{id: id}} -> id
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
