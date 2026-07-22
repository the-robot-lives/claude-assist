defmodule Therobotknows.Graph do
  @moduledoc "Knowledge graph payload from entries + entry_links."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Schema.Canon.{Entry, EntryLink}

  def graph(universe_id_or_slug, user_id, opts \\ []) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      type = Keyword.get(opts, :type)
      status = Keyword.get(opts, :status)
      tag = Keyword.get(opts, :tag)
      era = Keyword.get(opts, :era)
      region = Keyword.get(opts, :region)

      entries_q =
        from e in Entry,
          where: e.universe_id == ^universe.id and is_nil(e.deleted_at)

      entries_q =
        entries_q
        |> maybe_eq(:type, type)
        |> maybe_eq(:status, status)
        |> maybe_eq(:era, era)
        |> maybe_eq(:region, region)

      entries =
        if tag && tag != "" do
          from(e in entries_q,
            join: et in Therobotknows.Schema.Canon.EntryTag,
            on: et.entry_id == e.id,
            join: t in Therobotknows.Schema.Canon.Tag,
            on: t.id == et.tag_id,
            where: t.slug == ^tag
          )
          |> Repo.all()
        else
          Repo.all(entries_q)
        end

      entry_ids = Enum.map(entries, & &1.id)

      links =
        from(l in EntryLink,
          where:
            l.universe_id == ^universe.id and l.source_entry_id in ^entry_ids and
              l.target_entry_id in ^entry_ids
        )
        |> Repo.all()

      nodes =
        Enum.map(entries, fn e ->
          %{
            id: e.id,
            slug: e.slug,
            label: e.title,
            type: e.type,
            status: e.status,
            era: e.era,
            region: e.region
          }
        end)

      edges =
        Enum.map(links, fn l ->
          %{
            id: l.id,
            source: l.source_entry_id,
            target: l.target_entry_id,
            relationship: l.relationship,
            excerpt: l.excerpt
          }
        end)

      {:ok, %{nodes: nodes, edges: edges}}
    end
  end

  defp maybe_eq(q, _f, nil), do: q
  defp maybe_eq(q, _f, ""), do: q
  defp maybe_eq(q, f, v), do: from(e in q, where: field(e, ^f) == ^v)
end
