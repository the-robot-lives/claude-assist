defmodule TherobotplansWeb.WikiController do
  @moduledoc """
  REST controller for the Wiki domain. NOT mounted in router.ex — add the
  scope block there to expose these endpoints. Mirrors the item controller's
  authz style (direct Authz.authorize against the org_id path param).

  Ported from NPL WikiController, retuned for tobornalp's polymorphic
  trp_comments / trp_attachments / trp_reactions (a wiki comment/attachment is
  found via entity_id = page_id; a reaction on a comment uses entity_type =
  "wiki_comment").
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Wiki
  alias Therobotplans.Authz

  # ── Spaces ────────────────────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/wiki/spaces
  def index_spaces(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [organization_id: org_id]
        |> maybe_opt(:project_id, params["project_id"])
        |> maybe_opt(:search, params["search"])

      json(conn, %{spaces: Enum.map(Wiki.list_spaces(opts), &space_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/wiki/spaces
  def create_space(conn, %{"org_id" => org_id, "space" => attrs}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member"),
         {:ok, project_id} <- validate_project(attrs["project_id"], org_id) do
      params = %{
        organization_id: org_id,
        project_id: project_id,
        slug: attrs["slug"],
        name: attrs["name"],
        description: attrs["description"]
      }

      case Wiki.create_space(params) do
        {:ok, space} -> conn |> put_status(:created) |> json(%{space: space_json(space)})
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/wiki/spaces/:id
  def show_space(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_space(conn, org_id, id, "viewer", fn space ->
      json(conn, %{
        space: space_json(space),
        pages: Enum.map(Wiki.list_pages(space.id), &page_summary_json/1)
      })
    end)
  end

  # PUT /api/v1/organizations/:org_id/wiki/spaces/:id
  def update_space(conn, %{"org_id" => org_id, "id" => id, "space" => attrs}) do
    with_org_space(conn, org_id, id, "member", fn space ->
      patch =
        attrs
        |> Map.take(["slug", "name", "description"])
        |> maybe_put("project_id", Map.has_key?(attrs, "project_id"), attrs["project_id"])

      case Wiki.update_space(space.id, patch) do
        {:ok, updated} -> json(conn, %{space: space_json(updated)})
        {:error, :not_found} -> not_found(conn, "Space not found")
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/wiki/spaces/:id
  def delete_space(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_space(conn, org_id, id, "member", fn space ->
      case Wiki.delete_space(space.id) do
        {:ok, _} -> json(conn, %{message: "Space deleted"})
        {:error, :not_found} -> not_found(conn, "Space not found")
      end
    end)
  end

  # ── Pages ─────────────────────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/wiki/spaces/:space_id/pages
  def index_pages(conn, %{"org_id" => org_id, "space_id" => space_id} = params) do
    with_org_space(conn, org_id, space_id, "viewer", fn space ->
      opts = maybe_opt([], :search, params["search"])
      json(conn, %{pages: Enum.map(Wiki.list_pages(space.id, opts), &page_summary_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/wiki/spaces/:space_id/pages
  def create_page(conn, %{"org_id" => org_id, "space_id" => space_id, "page" => attrs}) do
    with_org_space(conn, org_id, space_id, "member", fn space ->
      params = %{
        space_id: space.id,
        parent_id: blank_to_nil(attrs["parent_id"]),
        slug: attrs["slug"],
        title: attrs["title"],
        content: attrs["content"],
        position: attrs["position"]
      }

      case Wiki.create_page(params) do
        {:ok, page} -> conn |> put_status(:created) |> json(%{page: page_json(page)})
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    end)
  end

  # GET /api/v1/organizations/:org_id/wiki/pages/:id
  def show_page(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_page(conn, org_id, id, "viewer", fn page ->
      body =
        page_json(page)
        |> Map.put(:comments, Enum.map(Wiki.list_comments(page.id), &comment_json/1))
        |> Map.put(:attachments, Enum.map(Wiki.list_attachments(page.id), &attachment_json/1))
        |> Map.put(:reactions, Enum.map(Wiki.list_reactions("page", page.id), &reaction_json/1))

      json(conn, %{page: body})
    end)
  end

  # PUT /api/v1/organizations/:org_id/wiki/pages/:id
  def update_page(conn, %{"org_id" => org_id, "id" => id, "page" => attrs}) do
    with_org_page(conn, org_id, id, "member", fn _page ->
      patch =
        attrs
        |> Map.take(["slug", "title", "content", "position"])
        |> maybe_put("parent_id", Map.has_key?(attrs, "parent_id"), blank_to_nil(attrs["parent_id"]))

      case Wiki.update_page(id, patch) do
        {:ok, updated} -> json(conn, %{page: page_json(updated)})
        {:error, :not_found} -> not_found(conn, "Page not found")
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/wiki/pages/:id
  def delete_page(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_page(conn, org_id, id, "member", fn _page ->
      case Wiki.delete_page(id) do
        {:ok, _} -> json(conn, %{message: "Page deleted"})
        {:error, :not_found} -> not_found(conn, "Page not found")
      end
    end)
  end

  # ── Comments ──────────────────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/wiki/pages/:page_id/comments
  def index_comments(conn, %{"org_id" => org_id, "page_id" => page_id}) do
    with_org_page(conn, org_id, page_id, "viewer", fn page ->
      json(conn, %{comments: Enum.map(Wiki.list_comments(page.id), &comment_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/wiki/pages/:page_id/comments
  def create_comment(conn, %{"org_id" => org_id, "page_id" => page_id, "comment" => attrs}) do
    with_org_page(conn, org_id, page_id, "member", fn page ->
      params = %{
        page_id: page.id,
        reply_to_id: blank_to_nil(attrs["reply_to_id"]),
        author: attrs["author"] || actor(conn),
        content: attrs["content"]
      }

      case Wiki.create_comment(params) do
        {:ok, comment} -> conn |> put_status(:created) |> json(%{comment: comment_json(comment)})
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/wiki/comments/:id
  def delete_comment(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_comment(conn, org_id, id, "member", fn comment ->
      case Wiki.delete_comment(comment.id) do
        {:ok, _} -> json(conn, %{message: "Comment deleted"})
        {:error, :not_found} -> not_found(conn, "Comment not found")
      end
    end)
  end

  # ── Attachments ───────────────────────────────────────────────────────────

  # GET /api/v1/organizations/:org_id/wiki/pages/:page_id/attachments
  def index_attachments(conn, %{"org_id" => org_id, "page_id" => page_id}) do
    with_org_page(conn, org_id, page_id, "viewer", fn page ->
      json(conn, %{attachments: Enum.map(Wiki.list_attachments(page.id), &attachment_json/1)})
    end)
  end

  # POST /api/v1/organizations/:org_id/wiki/pages/:page_id/attachments
  def create_attachment(conn, %{"org_id" => org_id, "page_id" => page_id, "attachment" => attrs}) do
    with_org_page(conn, org_id, page_id, "member", fn page ->
      params = %{
        page_id: page.id,
        artifact_type: attrs["artifact_type"] || "url",
        url: attrs["url"],
        git_branch: attrs["git_branch"],
        description: attrs["description"] || attrs["filename"],
        created_by: attrs["created_by"] || actor(conn)
      }

      case Wiki.create_attachment(params) do
        {:ok, attachment} -> conn |> put_status(:created) |> json(%{attachment: attachment_json(attachment)})
        {:error, changeset} -> unprocessable(conn, changeset)
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/wiki/attachments/:id
  def delete_attachment(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_attachment(conn, org_id, id, "member", fn _att ->
      case Wiki.delete_attachment(id) do
        {:ok, _} -> json(conn, %{message: "Attachment deleted"})
        {:error, :not_found} -> not_found(conn, "Attachment not found")
      end
    end)
  end

  # ── Reactions (pages + comments) ──────────────────────────────────────────

  # GET .../wiki/pages/:page_id/reactions
  def index_page_reactions(conn, %{"org_id" => org_id, "page_id" => page_id}) do
    with_org_page(conn, org_id, page_id, "viewer", fn page ->
      json(conn, %{reactions: Enum.map(Wiki.list_reactions("page", page.id), &reaction_json/1)})
    end)
  end

  # POST .../wiki/pages/:page_id/reactions  body: {emoji}
  def add_page_reaction(conn, %{"org_id" => org_id, "page_id" => page_id, "emoji" => emoji}) do
    with_org_page(conn, org_id, page_id, "member", fn page ->
      do_add_reaction(conn, "page", page.id, emoji)
    end)
  end

  # DELETE .../wiki/pages/:page_id/reactions  body/query: {emoji}
  def remove_page_reaction(conn, %{"org_id" => org_id, "page_id" => page_id, "emoji" => emoji}) do
    with_org_page(conn, org_id, page_id, "member", fn page ->
      do_remove_reaction(conn, "page", page.id, emoji)
    end)
  end

  # GET .../wiki/comments/:comment_id/reactions
  def index_comment_reactions(conn, %{"org_id" => org_id, "comment_id" => comment_id}) do
    with_org_comment(conn, org_id, comment_id, "viewer", fn comment ->
      json(conn, %{reactions: Enum.map(Wiki.list_reactions("comment", comment.id), &reaction_json/1)})
    end)
  end

  # POST .../wiki/comments/:comment_id/reactions  body: {emoji}
  def add_comment_reaction(conn, %{"org_id" => org_id, "comment_id" => comment_id, "emoji" => emoji}) do
    with_org_comment(conn, org_id, comment_id, "member", fn comment ->
      do_add_reaction(conn, "comment", comment.id, emoji)
    end)
  end

  # DELETE .../wiki/comments/:comment_id/reactions  body/query: {emoji}
  def remove_comment_reaction(conn, %{"org_id" => org_id, "comment_id" => comment_id, "emoji" => emoji}) do
    with_org_comment(conn, org_id, comment_id, "member", fn comment ->
      do_remove_reaction(conn, "comment", comment.id, emoji)
    end)
  end

  defp do_add_reaction(conn, target_type, target_id, emoji) do
    case Wiki.add_reaction(%{target_type: target_type, target_id: target_id, emoji: emoji, actor: actor(conn)}) do
      {:ok, reaction} -> conn |> put_status(:created) |> json(%{reaction: reaction_json(reaction)})
      {:error, changeset} -> unprocessable(conn, changeset)
    end
  end

  defp do_remove_reaction(conn, target_type, target_id, emoji) do
    case Wiki.remove_reaction(target_type, target_id, emoji, actor(conn)) do
      :ok -> json(conn, %{message: "Reaction removed"})
      {:error, :not_found} -> not_found(conn, "Reaction not found")
    end
  end

  # ── Shared resolution / authz helpers ─────────────────────────────────────

  # Authorize against the org, then load the space and ensure it belongs to it.
  defp with_org_space(conn, org_id, space_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         space when not is_nil(space) <- Wiki.get_space(space_id),
         true <- space.organization_id == org_id do
      fun.(space)
    else
      nil -> not_found(conn, "Space not found")
      false -> not_found(conn, "Space not found")
      err -> handle_error(conn, err)
    end
  end

  # Load a page, resolve its space, ensure the space belongs to the org.
  defp with_org_page(conn, org_id, page_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         page when not is_nil(page) <- Wiki.get_page(page_id),
         space when not is_nil(space) <- Wiki.get_space(page.space_id),
         true <- space.organization_id == org_id do
      fun.(page)
    else
      nil -> not_found(conn, "Page not found")
      false -> not_found(conn, "Page not found")
      err -> handle_error(conn, err)
    end
  end

  # A wiki comment lives in trp_comments (entity_type = "wiki_page"); its
  # entity_id is the page id, so resolve comment → page → space → org.
  defp with_org_comment(conn, org_id, comment_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         comment when not is_nil(comment) <- Wiki.get_comment(comment_id),
         page when not is_nil(page) <- page_from_comment(comment),
         space when not is_nil(space) <- Wiki.get_space(page.space_id),
         true <- space.organization_id == org_id do
      fun.(comment)
    else
      nil -> not_found(conn, "Comment not found")
      false -> not_found(conn, "Comment not found")
      err -> handle_error(conn, err)
    end
  end

  # Same chain for an attachment: trp_attachments.entity_id = page_id.
  defp with_org_attachment(conn, org_id, attachment_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         att when not is_nil(att) <- Wiki.get_attachment(attachment_id),
         page when not is_nil(page) <- Wiki.get_page(att.entity_id),
         space when not is_nil(space) <- Wiki.get_space(page.space_id),
         true <- space.organization_id == org_id do
      fun.(att)
    else
      nil -> not_found(conn, "Attachment not found")
      false -> not_found(conn, "Attachment not found")
      err -> handle_error(conn, err)
    end
  end

  # A wiki comment's entity_id is the page it's attached to.
  defp page_from_comment(%{entity_id: page_id}) when not is_nil(page_id),
    do: Wiki.get_page(page_id)

  defp validate_project(nil, _org_id), do: {:ok, nil}
  defp validate_project("", _org_id), do: {:ok, nil}

  defp validate_project(project_id, org_id) do
    case Therobotplans.Projects.get_project(project_id) do
      nil -> {:error, :project_not_in_org}
      %{organization_id: ^org_id} -> {:ok, project_id}
      _ -> {:error, :project_not_in_org}
    end
  end

  # ── JSON serializers ──────────────────────────────────────────────────────

  defp space_json(s) do
    %{
      id: s.id,
      organization_id: s.organization_id,
      project_id: s.project_id,
      slug: s.slug,
      name: s.name,
      description: s.description,
      inserted_at: s.inserted_at,
      updated_at: s.updated_at
    }
  end

  defp page_summary_json(p) do
    %{id: p.id, space_id: p.space_id, parent_id: p.parent_id, slug: p.slug, title: p.title, position: p.position, updated_at: p.updated_at}
  end

  defp page_json(p) do
    %{
      id: p.id,
      space_id: p.space_id,
      parent_id: p.parent_id,
      slug: p.slug,
      title: p.title,
      content: p.content,
      position: p.position,
      inserted_at: p.inserted_at,
      updated_at: p.updated_at
    }
  end

  # Polymorphic trp_comments shape: content / reply_to_id (not body / parent_id).
  defp comment_json(c) do
    %{id: c.id, page_id: c.entity_id, author: c.author, content: c.content, reply_to_id: c.reply_to_id, inserted_at: c.inserted_at}
  end

  # Polymorphic trp_attachments shape: artifact_type / url / description / created_by.
  defp attachment_json(a) do
    %{id: a.id, page_id: a.entity_id, artifact_type: a.artifact_type, url: a.url, description: a.description, created_by: a.created_by, inserted_at: a.inserted_at}
  end

  # Polymorphic trp_reactions shape: persona (not actor).
  defp reaction_json(r) do
    %{id: r.id, target_type: r.entity_type, target_id: r.entity_id, emoji: r.emoji, persona: r.persona, inserted_at: r.inserted_at}
  end

  # ── Misc ──────────────────────────────────────────────────────────────────

  defp not_found(conn, msg), do: conn |> put_status(:not_found) |> json(%{error: msg})

  defp unprocessable(conn, changeset),
    do: conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Organization not found"})
      {:error, :not_a_member} -> conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})
      {:error, :project_not_in_org} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "Project does not belong to this organization"})
      _ -> conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp maybe_opt(opts, _key, nil), do: opts
  defp maybe_opt(opts, _key, ""), do: opts
  defp maybe_opt(opts, key, val), do: Keyword.put(opts, key, val)

  defp maybe_put(map, _key, false, _val), do: map
  defp maybe_put(map, key, true, val), do: Map.put(map, key, val)

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp actor(conn), do: get_user_id(conn) || "anonymous"

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
