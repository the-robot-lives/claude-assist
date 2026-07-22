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
          ~w(title description status priority assignee queue_id parent_id custom_fields stage_id iteration_id rank start_date due_date estimate)
        )

      case Items.update(id, clean, actor: get_user_id(conn)) do
        {:ok, item} ->
          json(conn, %{item: item_to_json(item)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Item not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/items/:id
  def delete(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_item(conn, org_id, id, "member", fn item ->
      case Items.delete(item.id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Item not found"})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # ── Links (item ↔ item) ──────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/items/:id/links
  def links(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_item(conn, org_id, id, "viewer", fn item ->
      json(conn, %{links: links_to_json(Items.get_links(item.id))})
    end)
  end

  # POST /api/v1/organizations/:org_id/items/:id/links   body: {link: {target_item_id, link_type}}
  def create_link(conn, %{"org_id" => org_id, "id" => id, "link" => params}) do
    with_org_item(conn, org_id, id, "member", fn item ->
      case Items.link(item.id, params["target_item_id"], params["link_type"]) do
        {:ok, link} ->
          conn
          |> put_status(:created)
          |> json(%{
            link: %{
              id: link.id,
              source_item_id: link.source_item_id,
              target_item_id: link.target_item_id,
              link_type: link.link_type
            }
          })

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/items/links/:id
  def delete_link(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_link(conn, org_id, id, "member", fn _link ->
      case Items.delete_link(id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Link not found"})
      end
    end)
  end

  # ── Comments (polymorphic trp_comments, entity_type = "item") ────────────

  # GET /api/v1/organizations/:org_id/items/:id/comments
  def comments(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_item(conn, org_id, id, "viewer", fn item ->
      json(conn, %{comments: Enum.map(Items.list_comments(item.id), &comment_to_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/items/:id/comments   body: {comment: {content, author?, reply_to_id?}}
  def create_comment(conn, %{"org_id" => org_id, "id" => id, "comment" => attrs}) do
    with_org_item(conn, org_id, id, "member", fn item ->
      params = %{
        content: attrs["content"],
        author: attrs["author"] || get_user_id(conn),
        reply_to_id: blank_to_nil(attrs["reply_to_id"])
      }

      case Items.add_comment(item.id, params) do
        {:ok, comment} ->
          conn |> put_status(:created) |> json(%{comment: comment_to_json(comment)})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/items/comments/:id
  def delete_comment(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_comment(conn, org_id, id, "member", fn comment ->
      case Items.delete_comment(comment.id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Comment not found"})
      end
    end)
  end

  # ── Activity feed (item_events append-only audit) ────────────────────────

  # GET /api/v1/organizations/:org_id/items/:id/activity
  def activity(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_item(conn, org_id, id, "viewer", fn item ->
      json(conn, %{activity: Enum.map(Items.list_events(item.id), &event_to_json/1)})
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

  # An item comment lives in trp_comments with entity_type = "item"; its
  # entity_id is the item id, so resolve comment → item → org (blocks cross-org
  # comment probing by UUID — mirrors the OKR/wiki comment chain).
  defp with_org_comment(conn, org_id, comment_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         comment when not is_nil(comment) <- Items.get_comment(comment_id),
         item when not is_nil(item) <- Items.get(comment.entity_id),
         true <- item.organization_id == org_id do
      fun.(comment)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Comment not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Comment not found"})
      err -> handle_error(conn, err)
    end
  end

  # An item↔item link is org-scoped through its source item.
  defp with_org_link(conn, org_id, link_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         link when not is_nil(link) <- Items.get_link(link_id),
         item when not is_nil(item) <- Items.get(link.source_item_id),
         true <- item.organization_id == org_id do
      fun.(link)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Link not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Link not found"})
      err -> handle_error(conn, err)
    end
  end

  defp comment_to_json(c) do
    %{
      id: c.id,
      item_id: c.entity_id,
      content: c.content,
      author: c.author,
      reply_to_id: c.reply_to_id,
      inserted_at: c.inserted_at
    }
  end

  defp event_to_json(e) do
    %{
      id: e.id,
      item_id: e.item_id,
      actor: e.actor,
      field: e.field,
      old_value: e.old_value,
      new_value: e.new_value,
      occurred_at: e.occurred_at
    }
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
      rank: t.rank,
      start_date: t.start_date,
      due_date: t.due_date,
      estimate: t.estimate,
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

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

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
