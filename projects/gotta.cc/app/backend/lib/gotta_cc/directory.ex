defmodule GottaCc.Directory do
  @moduledoc """
  Context + repo for the public directory of hand-curated sites.

  Exposes category/site listing, filtering, and full-text search over the
  `directory_categories` / `directory_sites` tables (see changelog 025).
  """

  alias GottaCc.Directory.Category, as: Entity
  alias GottaCc.Schema.Directory.Category, as: CategorySchema
  alias GottaCc.Schema.Directory.Site, as: SiteSchema

  use Noizu.Repo
  def_repo(entity: Entity)

  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Categories
  # ---------------------------------------------------------------------------

  @doc """
  Lists all categories ordered by `display_order`, each enriched with a live
  `site_count` of published sites in that category.
  """
  def list_categories do
    count_query =
      from s in SiteSchema,
        where: s.status == "published",
        group_by: s.category_id,
        select: %{category_id: s.category_id, site_count: count(s.id)}

    counts =
      GottaCc.Repo.all(count_query)
      |> Map.new(fn %{category_id: id, site_count: c} -> {id, c} end)

    GottaCc.Repo.all(from c in CategorySchema, order_by: c.display_order)
    |> Enum.map(fn c -> Map.put(c, :site_count, Map.get(counts, c.id, 0)) end)
  end

  # ---------------------------------------------------------------------------
  # Sites
  # ---------------------------------------------------------------------------

  @doc """
  Lists published sites with optional filtering and sorting.

  Options:
    * `:category` — category slug to filter by
    * `:tag`      — tag string to filter by (`tags @> [tag]`)
    * `:sort`     — `:featured` | `:top` | `:newest` | `:random` (default `:top`)
    * `:limit`    — page size (default 24)
    * `:offset`   — page offset (default 0)
  """
  def list_sites(opts \\ []) do
    limit = opts[:limit] || 24
    offset = opts[:offset] || 0
    sort = opts[:sort] || :top

    base =
      from s in SiteSchema,
        where: s.status == "published",
        limit: ^limit,
        offset: ^offset,
        preload: [:category]

    base =
      case opts[:category] do
        nil -> base
        slug ->
          from s in base,
            join: c in assoc(s, :category),
            where: c.slug == ^slug
      end

    base =
      case opts[:tag] do
        nil -> base
        tag -> from s in base, where: fragment("? @> ?::text[]", s.tags, ^[tag])
      end

    base =
      case sort do
        :featured -> from s in base, order_by: [desc: s.featured, desc: s.overall_score]
        :newest   -> from s in base, order_by: [desc: s.inserted_at]
        :random   -> from s in base, order_by: fragment("random()")
        _         -> from s in base, order_by: [desc: s.overall_score]
      end

    GottaCc.Repo.all(base)
  end

  @doc """
  Fetches a single published site by slug, with its category preloaded.
  Returns `nil` if not found.
  """
  def get_site_by_slug(slug) when is_binary(slug) do
    GottaCc.Repo.one(
      from s in SiteSchema,
        where: s.slug == ^slug and s.status == "published",
        preload: [:category]
    )
  end

  @doc """
  Lists featured, published sites ordered by `overall_score` descending.
  """
  def list_featured(limit \\ 24) do
    GottaCc.Repo.all(
      from s in SiteSchema,
        where: s.featured == true and s.status == "published",
        order_by: [desc: s.overall_score],
        limit: ^limit,
        preload: [:category]
    )
  end

  @doc """
  Full-text search over published sites.

  Builds a `websearch_to_tsquery('english', q)` and ranks by `ts_rank` then
  `overall_score`. Falls back to a trigram `ILIKE` on name/domain/summary when
  the structured tsquery yields no matches.
  """
  def search_sites(q, opts \\ []) when is_binary(q) do
    limit = opts[:limit] || 24

    case String.trim(q) do
      "" ->
        []

      trimmed ->
        # Ecto query (not raw SQL) so Postgrex type decoders apply — uuid columns
        # come back as strings, overall_score as Decimal, and :category preloads.
        ts =
          from s in SiteSchema,
            where: fragment("search_vector @@ websearch_to_tsquery('english', ?)", ^trimmed),
            where: s.status == "published",
            order_by: [
              desc: fragment("ts_rank(search_vector, websearch_to_tsquery('english', ?))", ^trimmed),
              desc: s.overall_score
            ],
            limit: ^limit,
            preload: [:category]

        case GottaCc.Repo.all(ts) do
          [] -> trigram_search(trimmed, limit)
          sites -> sites
        end
    end
  end

  defp trigram_search(q, limit) do
    pattern = "%#{String.replace(q, "%", "\\%")}%"

    query =
      from s in SiteSchema,
        where: s.status == "published",
        where:
          fragment("? ILIKE ?", s.name, ^pattern) or
            fragment("? ILIKE ?", s.domain, ^pattern) or
            fragment("? ILIKE ?", s.summary, ^pattern),
        order_by: [
          desc: fragment("similarity(domain, ?)", ^q),
          desc: s.overall_score
        ],
        limit: ^limit,
        preload: [:category]

    GottaCc.Repo.all(query)
  end
end
