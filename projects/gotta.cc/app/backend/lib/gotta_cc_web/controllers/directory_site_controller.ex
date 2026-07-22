defmodule GottaCcWeb.DirectorySiteController do
  use GottaCcWeb, :controller

  alias GottaCc.Directory

  def index(conn, params) do
    opts = opts_from_params(params)

    sites =
      case params["q"] do
        q when is_binary(q) and q != "" -> Directory.search_sites(q, opts)
        _ -> Directory.list_sites(opts)
      end

    json(conn, %{sites: Enum.map(sites, &site_to_json/1)})
  end

  def show(conn, %{"slug" => slug}) do
    case Directory.get_site_by_slug(slug) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Site not found"})
      site -> json(conn, %{site: site_to_json(site)})
    end
  end

  defp opts_from_params(params) do
    [
      category: params["category"],
      tag: params["tag"],
      sort: parse_sort(params["sort"]),
      limit: parse_int(params["limit"], 24),
      offset: parse_int(params["offset"], 0)
    ]
  end

  defp parse_sort("featured"), do: :featured
  defp parse_sort("newest"), do: :newest
  defp parse_sort("random"), do: :random
  defp parse_sort("top"), do: :top
  defp parse_sort(_), do: :top

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_int(value, _default) when is_integer(value), do: value
  defp parse_int(_value, default), do: default

  defp site_to_json(%GottaCc.Schema.Directory.Site{} = s) do
    %{
      id: s.id,
      slug: s.slug,
      name: s.name,
      url: s.url,
      domain: s.domain,
      summary: s.summary,
      category: %{
        slug: s.category && s.category.slug,
        name: s.category && s.category.name
      },
      tags: s.tags,
      scores: %{
        originality: s.originality,
        human_authorship: s.human_authorship,
        depth: s.depth,
        freshness: s.freshness,
        design_quality: s.design_quality,
        overall: overall_to_integer(s.overall_score)
      },
      featured: s.featured
    }
  end

  defp overall_to_integer(nil), do: 0

  defp overall_to_integer(score) do
    score
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end
end
