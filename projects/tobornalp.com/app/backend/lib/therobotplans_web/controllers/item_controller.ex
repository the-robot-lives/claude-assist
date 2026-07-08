defmodule TherobotplansWeb.ItemController do
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Items
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/items
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [organization_id: org_id]
        |> maybe_opt(:project_id, params["project_id"])
        |> maybe_opt(:status, params["status"])
        |> maybe_opt(:item_type, params["item_type"])
        |> maybe_opt(:priority, params["priority"])
        |> maybe_opt(:assignee, params["assignee"])
        |> maybe_opt(:queue_id, params["queue_id"])
        |> maybe_opt(:parent_id, params["parent_id"])
        |> maybe_opt(:stage_id, params["stage_id"])
        |> maybe_opt(:iteration_id, params["iteration_id"])

      items = Items.list(opts)
      json(conn, %{items: Enum.map(items, &item_to_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/items
  def create(conn, %{"org_id" => org_id, "item" => item_params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member"),
         {:ok, project_id} <- validate_project(item_params["project_id"], org_id) do
      attrs = %{
        organization_id: org_id,
        project_id: project_id,
        title: item_params["title"],
        description: item_params["description"],
        item_type: item_params["item_type"] || "task",
        status: item_params["status"] || "open",
        priority: item_params["priority"],
        assignee: item_params["assignee"],
        reporter: item_params["reporter"] || user_id,
        queue_id: item_params["queue_id"],
        parent_id: item_params["parent_id"],
        stage_id: item_params["stage_id"],
        iteration_id: item_params["iteration_id"],
        custom_fields: item_params["custom_fields"] || %{}
      }

      case Items.create(attrs) do
        {:ok, item} ->
          conn |> put_status(:created) |> json(%{item: item_to_json(item)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/items/:id
  def show(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_item(conn, org_id, id, "viewer", fn item ->
      links = Items.get_links(item.id)
      json(conn, %{item: item_to_json(item), links: links_to_json(links)})
    end)
  end

  # PATCH/PUT /api/v1/organizations/:org_id/items/:id
  def update(conn, %{"org_id" => org_id, "id" => id, "item" => attrs}) do
    with_org_item(conn, org_id, id, "member", fn _item ->
      clean =
        Map.take(
          attrs,
          ~w(title description status priority assignee queue_id parent_id custom_fields stage_id iteration_id)
        )

      case Items.update(id, clean) do
        {:ok, item} ->
          json(conn, %{item: item_to_json(item)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Item not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # Resolve org, authorize, load the item, ensure it belongs to the org.
  defp with_org_item(conn, org_id, id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         item when not is_nil(item) <- fetch_item(org_id, id),
         true <- item.organization_id == org_id do
      fun.(item)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Item not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Item not found"})
      err -> handle_error(conn, err)
    end
  end

  # :id may be an item UUID or a human key (NOZINF-023). Key resolution is org-scoped.
  defp fetch_item(org_id, id_or_key) do
    case Ecto.UUID.cast(id_or_key) do
      {:ok, uuid} -> Items.get(uuid)
      :error -> Items.get_by_key(org_id, id_or_key)
    end
  end

  defp item_to_json(t) do
    %{
      id: t.id,
      key: t.key,
      number: t.number,
      organization_id: t.organization_id,
      project_id: t.project_id,
      title: t.title,
      description: t.description,
      item_type: t.item_type,
      status: t.status,
      priority: t.priority,
      assignee: t.assignee,
      reporter: t.reporter,
      queue_id: t.queue_id,
      parent_id: t.parent_id,
      stage_id: t.stage_id,
      iteration_id: t.iteration_id,
      custom_fields: t.custom_fields,
      inserted_at: t.inserted_at,
      updated_at: t.updated_at
    }
  end

  defp links_to_json(%{outgoing: out, incoming: inc}) do
    %{
      outgoing:
        Enum.map(out, &%{id: &1.id, link_type: &1.link_type, target_item_id: &1.target_item_id}),
      incoming:
        Enum.map(inc, &%{id: &1.id, link_type: &1.link_type, source_item_id: &1.source_item_id})
    }
  end

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
