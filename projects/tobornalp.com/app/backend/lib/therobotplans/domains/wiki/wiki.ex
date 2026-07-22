defmodule Therobotplans.Domains.Wiki do
  @moduledoc """
  Wiki domain context: spaces, pages, comments, attachments, and reactions.

  Spaces are org-required (optionally project-scoped). Pages live in a space and
  may nest. Comments, attachments, and reactions are NOT wiki-specific tables —
  they reuse the polymorphic trp_comments / trp_attachments / trp_reactions
  tables (changelog 027) via Services.Comment / Services.Attach /
  Services.Reaction. Wiki pages use entity_type = "wiki_page"; reactions on wiki
  comments use entity_type = "wiki_comment".

  Ported from NPL Domains.Wiki, retuned for tobornalp's polymorphic cross-cutting
  tables (NPL kept its own wiki_comments / wiki_attachments / wiki_reactions).
  """

  import Ecto.Query, except: [update: 2]

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Wiki.{Space, Page}
  # Polymorphic cross-cutting schemas (for direct get/delete by id).
  alias Therobotplans.Schema.Comment
  alias Therobotplans.Schema.Attachment
  # Polymorphic cross-cutting services (Comments avoids the Schema.Comment clash).
  alias Therobotplans.Services.Comment, as: Comments
  alias Therobotplans.Services.Attach
  alias Therobotplans.Services.Reaction

  # entity_type keys for the polymorphic cross-cutting tables
  @page_entity "wiki_page"
  @comment_entity "wiki_comment"

  # ── Spaces ────────────────────────────────────────────────────────────────

  def list_spaces(opts \\ []) do
    Space
    |> maybe_where(:organization_id, opts[:organization_id])
    |> maybe_where(:project_id, opts[:project_id])
    |> maybe_search([:name, :slug], opts[:search])
    |> order_by([s], asc: s.name)
    |> limit(^(opts[:limit] || 100))
    |> offset(^(opts[:offset] || 0))
    |> Repo.all()
  end

  def get_space(id), do: Repo.get(Space, id)

  def get_space_by_slug(org_id, slug),
    do: Repo.get_by(Space, organization_id: org_id, slug: slug)

  def create_space(attrs) do
    attrs = default_slug(attrs, :name)

    %Space{}
    |> Space.changeset(attrs)
    |> Repo.insert()
  end

  def update_space(id, attrs) do
    case get_space(id) do
      nil -> {:error, :not_found}
      space -> space |> Space.changeset(attrs) |> Repo.update()
    end
  end

  def delete_space(id) do
    case get_space(id) do
      nil -> {:error, :not_found}
      space -> Repo.delete(space)
    end
  end

  # ── Pages ─────────────────────────────────────────────────────────────────

  def list_pages(space_id, opts \\ []) do
    Page
    |> where([p], p.space_id == ^space_id)
    |> maybe_where(:parent_id, opts[:parent_id])
    |> maybe_search([:title, :slug], opts[:search])
    |> order_by([p], asc: p.position, asc: p.title)
    |> limit(^(opts[:limit] || 200))
    |> Repo.all()
  end

  def get_page(id), do: Repo.get(Page, id)

  def create_page(attrs) do
    attrs = default_slug(attrs, :title)

    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  def update_page(id, attrs) do
    case get_page(id) do
      nil -> {:error, :not_found}
      page -> page |> Page.changeset(attrs) |> Repo.update()
    end
  end

  def delete_page(id) do
    case get_page(id) do
      nil -> {:error, :not_found}
      page -> Repo.delete(page)
    end
  end

  # ── Comments (polymorphic trp_comments, entity_type = "wiki_page") ────────

  def list_comments(page_id), do: Comments.list(@page_entity, page_id)

  def get_comment(id), do: Repo.get(Comment, id)

  def create_comment(attrs) do
    page_id = fetch(attrs, :page_id)
    Comments.add(@page_entity, page_id, comment_attrs(attrs))
  end

  def delete_comment(id) do
    case get_comment(id) do
      nil -> {:error, :not_found}
      comment -> Repo.delete(comment)
    end
  end

  # ── Attachments (polymorphic trp_attachments, entity_type = "wiki_page") ──

  def list_attachments(page_id), do: Attach.list(@page_entity, page_id)

  def get_attachment(id), do: Repo.get(Attachment, id)

  def create_attachment(attrs) do
    page_id = fetch(attrs, :page_id)
    Attach.add(@page_entity, page_id, attachment_attrs(attrs))
  end

  def delete_attachment(id), do: Attach.remove(id)

  # ── Reactions (polymorphic trp_reactions) ─────────────────────────────────
  # target_type "page" → entity_type "wiki_page"; "comment" → "wiki_comment".

  def list_reactions(target_type, target_id) do
    Reaction.list(entity_for(target_type), target_id)
  end

  @doc "Idempotent: re-adding the same (target, emoji, persona) is a no-op."
  def add_reaction(attrs) do
    target_type = fetch(attrs, :target_type)
    target_id = fetch(attrs, :target_id)
    emoji = fetch(attrs, :emoji)
    persona = fetch(attrs, :actor) || fetch(attrs, :persona) || "mcp"

    Reaction.add(entity_for(target_type), target_id, persona, emoji)
  end

  def remove_reaction(target_type, target_id, emoji, persona) do
    Reaction.remove(entity_for(target_type), target_id, persona, emoji)
  end

  @doc "The polymorphic entity_type for a wiki reaction target."
  def entity_for("page"), do: @page_entity
  def entity_for("comment"), do: @comment_entity
  def entity_for(@page_entity), do: @page_entity
  def entity_for(@comment_entity), do: @comment_entity

  # ── Counts (overview) ─────────────────────────────────────────────────────

  def count_spaces(org_id) do
    Space |> where([s], s.organization_id == ^org_id) |> Repo.aggregate(:count, :id)
  end

  def count_pages(org_id) do
    Page
    |> join(:inner, [p], s in Space, on: s.id == p.space_id)
    |> where([_p, s], s.organization_id == ^org_id)
    |> Repo.aggregate(:count, :id)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp comment_attrs(attrs) do
    # NPL wiki comments used (parent_id, author, body); trp_comments uses
    # (reply_to_id, author, content). Map the legacy keys through.
    %{
      content: fetch(attrs, :body) || fetch(attrs, :content),
      author: fetch(attrs, :author),
      reply_to_id: fetch(attrs, :parent_id) || fetch(attrs, :reply_to_id)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp attachment_attrs(attrs) do
    # trp_attachments is artifact-typed (artifact_type, url, git_branch,
    # description, created_by). Wiki attachments carry a filename/mime/url, so we
    # default artifact_type to "url" and surface the original filename in the
    # description when no description is supplied.
    filename = fetch(attrs, :filename)
    url = fetch(attrs, :url)

    %{
      artifact_type: fetch(attrs, :artifact_type) || "url",
      url: url,
      description: fetch(attrs, :description) || filename,
      created_by: fetch(attrs, :created_by) || fetch(attrs, :author)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp fetch(attrs, k), do: attrs[k] || attrs[Atom.to_string(k)]

  defp maybe_where(query, _field, nil), do: query
  defp maybe_where(query, field, value), do: where(query, [r], field(r, ^field) == ^value)

  defp maybe_search(query, _fields, nil), do: query
  defp maybe_search(query, _fields, ""), do: query

  defp maybe_search(query, [a, b], search) do
    pattern = "%#{search}%"
    where(query, [r], ilike(field(r, ^a), ^pattern) or ilike(field(r, ^b), ^pattern))
  end

  # Derive a slug from the given source field when none is provided.
  defp default_slug(attrs, source) do
    slug = fetch(attrs, :slug)
    name = fetch(attrs, source)

    cond do
      is_binary(slug) and slug != "" -> attrs
      is_binary(name) -> Map.put(attrs, :slug, slugify(name))
      true -> attrs
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
