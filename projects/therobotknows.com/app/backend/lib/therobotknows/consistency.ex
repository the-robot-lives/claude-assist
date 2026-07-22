defmodule Therobotknows.Consistency do
  @moduledoc "v0.1 consistency checks: duplicate names, orphan links, lite timeline."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Schema.Consistency.Issue
  alias Therobotknows.Schema.Canon.{Entry, EntryLink}

  def list_issues(universe_id_or_slug, user_id, opts \\ []) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      status = Keyword.get(opts, :status, "open")

      q =
        from i in Issue,
          where: i.universe_id == ^universe.id,
          order_by: [asc: i.severity, desc: i.inserted_at]

      q = if status && status != "all", do: from(i in q, where: i.status == ^status), else: q

      issues = Repo.all(q) |> Enum.map(&to_map/1)
      {:ok, %{issues: issues}}
    end
  end

  def get_issue(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Issue{} = issue <- Repo.get_by(Issue, id: id, universe_id: universe.id) do
      {:ok, to_map(issue)}
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def resolve(universe_id_or_slug, id, resolution, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Issue{} = issue <- Repo.get_by(Issue, id: id, universe_id: universe.id) do
      status = Map.get(resolution, "status") || Map.get(resolution, :status) || "resolved"

      issue
      |> Issue.changeset(%{
        status: status,
        resolution: resolution
      })
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, to_map(updated)}
        e -> e
      end
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def run_checks(universe_id_or_slug, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor) do
      # Clear open auto issues of known kinds before re-run
      from(i in Issue,
        where:
          i.universe_id == ^universe.id and i.status == "open" and
            i.kind in ["duplicate_name", "orphaned_reference", "timeline_lite"]
      )
      |> Repo.delete_all()

      entries =
        from(e in Entry, where: e.universe_id == ^universe.id and is_nil(e.deleted_at))
        |> Repo.all()

      links =
        from(l in EntryLink, where: l.universe_id == ^universe.id) |> Repo.all()

      issues =
        []
        |> Kernel.++(duplicate_name_issues(universe.id, entries))
        |> Kernel.++(orphan_link_issues(universe.id, entries, links))
        |> Kernel.++(timeline_lite_issues(universe.id, entries))

      Enum.each(issues, fn attrs ->
        %Issue{}
        |> Issue.changeset(attrs)
        |> Repo.insert()
      end)

      {:ok, %{issues_found: length(issues), issues: Enum.map(issues, &preview/1)}}
    end
  end

  defp duplicate_name_issues(universe_id, entries) do
    entries
    |> Enum.group_by(fn e -> String.downcase(e.title || "") end)
    |> Enum.filter(fn {title, group} -> title != "" and length(group) > 1 end)
    |> Enum.map(fn {title, group} ->
      ids = Enum.map(group, & &1.id)

      %{
        universe_id: universe_id,
        severity: "error",
        kind: "duplicate_name",
        title: "Duplicate name — '#{hd(group).title}' appears #{length(group)} times",
        detail: "Multiple entries share the title \"#{hd(group).title}\" (normalized: #{title}).",
        entry_ids: ids,
        status: "open"
      }
    end)
  end

  defp orphan_link_issues(universe_id, entries, links) do
    ids = MapSet.new(Enum.map(entries, & &1.id))

    links
    |> Enum.filter(fn l ->
      not MapSet.member?(ids, l.source_entry_id) or not MapSet.member?(ids, l.target_entry_id)
    end)
    |> Enum.map(fn l ->
      %{
        universe_id: universe_id,
        severity: "warning",
        kind: "orphaned_reference",
        title: "Orphaned link — #{l.relationship}",
        detail: "Link references a missing or deleted entry.",
        entry_ids: Enum.filter([l.source_entry_id, l.target_entry_id], &MapSet.member?(ids, &1)),
        status: "open"
      }
    end)
  end

  defp timeline_lite_issues(universe_id, entries) do
    # Lite: entries with metadata dates that contradict shared era labels when both present
    with_years =
      entries
      |> Enum.map(fn e ->
        year = get_in(e.metadata || %{}, ["year"]) || get_in(e.metadata || %{}, ["date_year"])
        {e, parse_year(year)}
      end)
      |> Enum.filter(fn {_e, y} -> is_integer(y) end)

    with_years
    |> Enum.group_by(fn {e, _} -> e.era end)
    |> Enum.flat_map(fn
      {nil, _} ->
        []

      {"", _} ->
        []

      {era, group} when length(group) > 1 ->
        years = Enum.map(group, fn {_, y} -> y end)
        span = Enum.max(years) - Enum.min(years)

        if span > 500 do
          [
            %{
              universe_id: universe_id,
              severity: "suggestion",
              kind: "timeline_lite",
              title: "Wide date span within era '#{era}'",
              detail:
                "Entries tagged era \"#{era}\" have year metadata spanning #{span} years — possible timeline conflict.",
              entry_ids: Enum.map(group, fn {e, _} -> e.id end),
              status: "open"
            }
          ]
        else
          []
        end

      _ ->
        []
    end)
  end

  defp parse_year(nil), do: nil
  defp parse_year(y) when is_integer(y), do: y

  defp parse_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_year(_), do: nil

  defp to_map(%Issue{} = i) do
    %{
      id: i.id,
      universe_id: i.universe_id,
      severity: i.severity,
      kind: i.kind,
      title: i.title,
      detail: i.detail,
      entry_ids: i.entry_ids || [],
      status: i.status,
      resolution: i.resolution,
      inserted_at: i.inserted_at,
      updated_at: i.updated_at
    }
  end

  defp preview(attrs) when is_map(attrs) do
    Map.take(attrs, [:severity, :kind, :title, :entry_ids])
  end
end
