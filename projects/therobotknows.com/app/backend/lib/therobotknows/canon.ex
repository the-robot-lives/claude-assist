defmodule Therobotknows.Canon do
  @moduledoc """
  Canon entry, link, and tag domain for knowledge bases.
  """

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Schema.Canon.{Entry, EntryLink, EntryTag, EntryTemplate, EntryVersion, Tag}

  def list_entries(universe_id_or_slug, user_id, opts \\ []) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      page = Keyword.get(opts, :page, 1)
      per_page = min(Keyword.get(opts, :per_page, 25), 100)
      offset = (page - 1) * per_page

      base =
        from e in Entry,
          where: e.universe_id == ^universe.id and is_nil(e.deleted_at),
          order_by: [desc: e.updated_at]

      base = apply_entry_filters(base, opts)
      total = Repo.aggregate(base, :count, :id)

      entries =
        base
        |> limit(^per_page)
        |> offset(^offset)
        |> Repo.all()
        |> Repo.preload(:tags)
        |> Enum.map(&entry_to_map(&1, false))

      {:ok,
       %{
         entries: entries,
         meta: %{
           page: page,
           per_page: per_page,
           total: total,
           total_pages: max(1, ceil_div(total, per_page))
         }
       }}
    end
  end

  def get_entry(universe_id_or_slug, entry_id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      entry = Repo.preload(entry, :tags)
      links = list_links_for_entry(universe.id, entry.id)
      {:ok, entry_to_map(entry, true) |> Map.put(:links, links)}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def create_entry(universe_id_or_slug, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor) do
      tag_names = Map.get(attrs, "tag_names") || Map.get(attrs, :tag_names) || []

      body = Map.get(attrs, "body") || Map.get(attrs, :body) || %{}

      cs =
        %Entry{}
        |> Entry.changeset(%{
          universe_id: universe.id,
          type: Map.get(attrs, "type") || Map.get(attrs, :type),
          status: Map.get(attrs, "status") || Map.get(attrs, :status) || "draft",
          title: Map.get(attrs, "title") || Map.get(attrs, :title),
          slug: Map.get(attrs, "slug") || Map.get(attrs, :slug),
          excerpt: Map.get(attrs, "excerpt") || Map.get(attrs, :excerpt),
          body: body,
          era: Map.get(attrs, "era") || Map.get(attrs, :era),
          region: Map.get(attrs, "region") || Map.get(attrs, :region),
          metadata: Map.get(attrs, "metadata") || Map.get(attrs, :metadata) || %{},
          created_by: user_id
        })

      Repo.transaction(fn ->
        case Repo.insert(cs) do
          {:ok, entry} ->
            _ = replace_tags(entry, universe.id, tag_names)
            _ = snapshot_entry!(entry, user_id, "create")
            entry = Repo.preload(entry, :tags, force: true)
            entry_to_map(entry, true)

          {:error, reason} ->
            Repo.rollback(reason)
        end
      end)
    end
  end

  def update_entry(universe_id_or_slug, entry_id, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      tag_names = Map.get(attrs, "tag_names") || Map.get(attrs, :tag_names)

      updates =
        %{}
        |> maybe_put(:type, Map.get(attrs, "type") || Map.get(attrs, :type))
        |> maybe_put(:status, Map.get(attrs, "status") || Map.get(attrs, :status))
        |> maybe_put(:title, Map.get(attrs, "title") || Map.get(attrs, :title))
        |> maybe_put(:slug, Map.get(attrs, "slug") || Map.get(attrs, :slug))
        |> maybe_put(:excerpt, Map.get(attrs, "excerpt") || Map.get(attrs, :excerpt))
        |> maybe_put(:body, Map.get(attrs, "body") || Map.get(attrs, :body))
        |> maybe_put(:era, Map.get(attrs, "era") || Map.get(attrs, :era))
        |> maybe_put(:region, Map.get(attrs, "region") || Map.get(attrs, :region))
        |> maybe_put(:metadata, Map.get(attrs, "metadata") || Map.get(attrs, :metadata))
        |> Map.put(:version, entry.version + 1)

      Repo.transaction(fn ->
        case entry |> Entry.changeset(updates) |> Repo.update() do
          {:ok, updated} ->
            if is_list(tag_names), do: replace_tags(updated, universe.id, tag_names)
            _ = snapshot_entry!(updated, user_id, "update")
            updated = Repo.preload(updated, :tags, force: true)
            entry_to_map(updated, true)

          {:error, reason} ->
            Repo.rollback(reason)
        end
      end)
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def delete_entry(universe_id_or_slug, entry_id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      entry |> Entry.soft_delete_changeset() |> Repo.update()
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def transition_status(universe_id_or_slug, entry_id, new_status, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      if Entry.allowed_transition?(entry.status, new_status) do
        entry
        |> Entry.changeset(%{status: new_status, version: entry.version + 1})
        |> Repo.update()
        |> case do
          {:ok, updated} ->
            _ = snapshot_entry!(updated, user_id, "status")
            updated = Repo.preload(updated, :tags)
            {:ok, entry_to_map(updated, true)}

          error ->
            error
        end
      else
        {:error, {:invalid_transition, entry.status, new_status}}
      end
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def list_links(universe_id_or_slug, entry_id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      {:ok, list_links_for_entry(universe.id, entry.id)}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def create_link(universe_id_or_slug, source_entry_id, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = source <- get_entry_record(universe.id, source_entry_id),
         target_id when is_binary(target_id) <-
           Map.get(attrs, "target_entry_id") || Map.get(attrs, :target_entry_id),
         %Entry{} = _target <- get_entry_record(universe.id, target_id) do
      %EntryLink{}
      |> EntryLink.changeset(%{
        universe_id: universe.id,
        source_entry_id: source.id,
        target_entry_id: target_id,
        relationship: Map.get(attrs, "relationship") || Map.get(attrs, :relationship),
        excerpt: Map.get(attrs, "excerpt") || Map.get(attrs, :excerpt),
        created_by: user_id
      })
      |> Repo.insert()
      |> case do
        {:ok, link} -> {:ok, link_to_map(link)}
        error -> error
      end
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def delete_link(universe_id_or_slug, link_id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor) do
      case Repo.get_by(EntryLink, id: link_id, universe_id: universe.id) do
        nil -> {:error, :not_found}
        link -> Repo.delete(link)
      end
    end
  end

  def list_tags(universe_id_or_slug, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      tags =
        from(t in Tag,
          left_join: et in EntryTag,
          on: et.tag_id == t.id,
          where: t.universe_id == ^universe.id,
          group_by: t.id,
          select: %{
            id: t.id,
            name: t.name,
            slug: t.slug,
            entry_count: count(et.entry_id)
          },
          order_by: [asc: t.name]
        )
        |> Repo.all()

      {:ok, tags}
    end
  end

  def create_tag(universe_id_or_slug, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor) do
      name = Map.get(attrs, "name") || Map.get(attrs, :name)

      %Tag{}
      |> Tag.changeset(%{
        universe_id: universe.id,
        name: name,
        slug: Tag.slugify(name)
      })
      |> Repo.insert()
      |> case do
        {:ok, tag} -> {:ok, %{id: tag.id, name: tag.name, slug: tag.slug}}
        error -> error
      end
    end
  end

  def replace_entry_tags(universe_id_or_slug, entry_id, tag_names, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      replace_tags(entry, universe.id, tag_names || [])
      entry = Repo.preload(entry, :tags, force: true)
      {:ok, entry_to_map(entry, true)}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def list_templates do
    from(t in EntryTemplate, order_by: [asc: t.type])
    |> Repo.all()
    |> Enum.map(fn t ->
      %{
        type: t.type,
        name: t.name,
        fields: t.fields || [],
        body_skeleton: t.body_skeleton
      }
    end)
  end

  def list_versions(universe_id_or_slug, entry_id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id) do
      versions =
        from(v in EntryVersion,
          where: v.entry_id == ^entry.id,
          order_by: [desc: v.version],
          select: %{
            id: v.id,
            version: v.version,
            reason: v.reason,
            created_by: v.created_by,
            inserted_at: v.inserted_at
          }
        )
        |> Repo.all()

      {:ok, versions}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def get_version(universe_id_or_slug, entry_id, version_num, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id),
         %EntryVersion{} = v <-
           Repo.get_by(EntryVersion, entry_id: entry.id, version: version_num) do
      {:ok,
       %{
         id: v.id,
         version: v.version,
         reason: v.reason,
         created_by: v.created_by,
         inserted_at: v.inserted_at,
         snapshot: v.snapshot
       }}
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def restore_version(universe_id_or_slug, entry_id, version_num, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Entry{} = entry <- get_entry_record(universe.id, entry_id),
         %EntryVersion{} = v <-
           Repo.get_by(EntryVersion, entry_id: entry.id, version: version_num) do
      snap = v.snapshot || %{}

      updates = %{
        title: Map.get(snap, "title") || Map.get(snap, :title) || entry.title,
        excerpt: Map.get(snap, "excerpt") || Map.get(snap, :excerpt),
        body: Map.get(snap, "body") || Map.get(snap, :body) || entry.body,
        type: Map.get(snap, "type") || Map.get(snap, :type) || entry.type,
        status: Map.get(snap, "status") || Map.get(snap, :status) || entry.status,
        era: Map.get(snap, "era") || Map.get(snap, :era),
        region: Map.get(snap, "region") || Map.get(snap, :region),
        metadata: Map.get(snap, "metadata") || Map.get(snap, :metadata) || %{},
        version: entry.version + 1
      }

      case entry |> Entry.changeset(updates) |> Repo.update() do
        {:ok, updated} ->
          _ = snapshot_entry!(updated, user_id, "restore")
          updated = Repo.preload(updated, :tags)
          {:ok, entry_to_map(updated, true)}

        error ->
          error
      end
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def search(universe_id_or_slug, user_id, opts \\ []) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      q = Keyword.get(opts, :q, "") |> to_string() |> String.trim()
      page = Keyword.get(opts, :page, 1)
      per_page = min(Keyword.get(opts, :per_page, 25), 100)
      offset = (page - 1) * per_page

      base =
        from e in Entry,
          where: e.universe_id == ^universe.id and is_nil(e.deleted_at)

      base = apply_entry_filters(base, opts)

      base =
        if q == "" do
          base
        else
          like = "%#{q}%"

          from e in base,
            where:
              ilike(e.title, ^like) or ilike(e.excerpt, ^like) or
                fragment("?::text ILIKE ?", e.body, ^like) or
                fragment(
                  "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ plainto_tsquery('english', ?)",
                  e.title,
                  e.excerpt,
                  ^q
                )
        end

      total = Repo.aggregate(base, :count, :id)

      entries =
        base
        |> order_by([e], desc: e.updated_at)
        |> limit(^per_page)
        |> offset(^offset)
        |> Repo.all()
        |> Repo.preload(:tags)
        |> Enum.map(fn e ->
          entry_to_map(e, false)
          |> Map.put(:snippet, e.excerpt || String.slice(e.title || "", 0, 160))
        end)

      {:ok,
       %{
         results: entries,
         meta: %{
           page: page,
           per_page: per_page,
           total: total,
           total_pages: max(1, ceil_div(total, per_page))
         }
       }}
    end
  end

  def export_universe(universe_id_or_slug, user_id, format \\ "json") do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      all_entries =
        case list_entries(universe.id, user_id, page: 1, per_page: 100) do
          {:ok, %{entries: es, meta: %{total: t}}} when t > 100 ->
            pages = ceil_div(t, 100)

            Enum.reduce(2..max(pages, 2), es, fn p, acc ->
              case list_entries(universe.id, user_id, page: p, per_page: 100) do
                {:ok, %{entries: more}} -> acc ++ more
                _ -> acc
              end
            end)

          {:ok, %{entries: es}} ->
            es

          _ ->
            []
        end

      links =
        from(l in EntryLink, where: l.universe_id == ^universe.id)
        |> Repo.all()
        |> Enum.map(&link_to_map/1)

      payload = %{
        universe: %{
          id: universe.id,
          slug: universe.slug,
          name: universe.name,
          description: universe.description,
          genre: universe.genre,
          tone: universe.tone,
          config: universe.config
        },
        entries: all_entries,
        links: links,
        exported_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      case format do
        "markdown" -> {:ok, :markdown, export_markdown(payload)}
        _ -> {:ok, :json, Jason.encode!(payload, pretty: true)}
      end
    end
  end

  defp snapshot_entry!(%Entry{} = entry, user_id, reason) do
    entry = Repo.preload(entry, :tags)

    snapshot = %{
      "title" => entry.title,
      "excerpt" => entry.excerpt,
      "body" => entry.body,
      "type" => entry.type,
      "status" => entry.status,
      "era" => entry.era,
      "region" => entry.region,
      "metadata" => entry.metadata || %{},
      "tags" => Enum.map(entry.tags || [], & &1.name)
    }

    %EntryVersion{}
    |> EntryVersion.changeset(%{
      entry_id: entry.id,
      version: entry.version,
      snapshot: snapshot,
      created_by: user_id,
      reason: reason,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
    |> Repo.insert()
  end

  defp export_markdown(%{universe: u, entries: entries}) do
    header = """
    # #{u.name}

    #{u.description || ""}

    Genre: #{u.genre || "—"} · Tone: #{u.tone || "—"}

    ---

    """

    body =
      entries
      |> Enum.map(fn e ->
        tags =
          (e[:tags] || e["tags"] || [])
          |> Enum.map(fn t ->
            cond do
              is_map(t) -> t[:name] || t["name"] || ""
              is_binary(t) -> t
              true -> ""
            end
          end)
          |> Enum.join(", ")

        body = e[:body] || e["body"]

        body_text =
          cond do
            is_binary(body) -> body
            is_map(body) -> Map.get(body, "text") || Jason.encode!(body)
            true -> ""
          end

        """
        ## #{e[:title] || e["title"]}

        _#{e[:type] || e["type"]} · #{e[:status] || e["status"]}_

        #{e[:excerpt] || e["excerpt"] || ""}

        #{body_text}

        Tags: #{tags}

        """
      end)
      |> Enum.join("\n---\n\n")

    header <> body
  end

  defp get_entry_record(universe_id, entry_id) do
    from(e in Entry,
      where: e.id == ^entry_id and e.universe_id == ^universe_id and is_nil(e.deleted_at)
    )
    |> Repo.one()
  end

  defp list_links_for_entry(universe_id, entry_id) do
    from(l in EntryLink,
      where:
        l.universe_id == ^universe_id and
          (l.source_entry_id == ^entry_id or l.target_entry_id == ^entry_id)
    )
    |> Repo.all()
    |> Enum.map(&link_to_map/1)
  end

  defp replace_tags(entry, universe_id, tag_names) when is_list(tag_names) do
    from(et in EntryTag, where: et.entry_id == ^entry.id) |> Repo.delete_all()

    Enum.each(tag_names, fn name ->
      slug = Tag.slugify(name)

      tag =
        case Repo.get_by(Tag, universe_id: universe_id, slug: slug) do
          nil ->
            {:ok, t} =
              %Tag{}
              |> Tag.changeset(%{universe_id: universe_id, name: name, slug: slug})
              |> Repo.insert()

            t

          t ->
            t
        end

      Repo.insert_all("entry_tags", [
        %{
          entry_id: entry.id,
          tag_id: tag.id,
          inserted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
        }
      ],
      on_conflict: :nothing
      )
    end)
  end

  defp apply_entry_filters(query, opts) do
    query
    |> maybe_filter(:type, Keyword.get(opts, :type))
    |> maybe_filter(:status, Keyword.get(opts, :status))
    |> maybe_filter(:era, Keyword.get(opts, :era))
    |> maybe_filter(:region, Keyword.get(opts, :region))
    |> maybe_filter_tag(Keyword.get(opts, :tag))
    |> maybe_filter_q(Keyword.get(opts, :q))
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, _field, ""), do: query

  defp maybe_filter(query, field, value) do
    from e in query, where: field(e, ^field) == ^value
  end

  defp maybe_filter_tag(query, nil), do: query
  defp maybe_filter_tag(query, ""), do: query

  defp maybe_filter_tag(query, tag_slug) do
    from e in query,
      join: et in EntryTag,
      on: et.entry_id == e.id,
      join: t in Tag,
      on: t.id == et.tag_id,
      where: t.slug == ^tag_slug
  end

  defp maybe_filter_q(query, nil), do: query
  defp maybe_filter_q(query, ""), do: query

  defp maybe_filter_q(query, q) do
    like = "%#{q}%"
    from e in query, where: ilike(e.title, ^like) or ilike(e.excerpt, ^like)
  end

  defp entry_to_map(%Entry{} = e, include_body) do
    base = %{
      id: e.id,
      universe_id: e.universe_id,
      type: e.type,
      status: e.status,
      title: e.title,
      slug: e.slug,
      excerpt: e.excerpt,
      era: e.era,
      region: e.region,
      metadata: e.metadata || %{},
      tags: Enum.map(e.tags || [], &%{id: &1.id, name: &1.name, slug: &1.slug}),
      word_count: e.word_count,
      version: e.version,
      created_by: e.created_by,
      inserted_at: e.inserted_at,
      updated_at: e.updated_at
    }

    if include_body, do: Map.put(base, :body, e.body), else: base
  end

  defp link_to_map(%EntryLink{} = l) do
    %{
      id: l.id,
      source_entry_id: l.source_entry_id,
      target_entry_id: l.target_entry_id,
      relationship: l.relationship,
      excerpt: l.excerpt
    }
  end

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)

  defp ceil_div(0, _), do: 0
  defp ceil_div(a, b), do: div(a + b - 1, b)
end
