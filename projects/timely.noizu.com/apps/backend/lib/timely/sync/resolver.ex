defmodule Timely.Sync.Resolver do
  @moduledoc """
  Name-to-id resolution, the genuine impedance mismatch in Timely
  (SYNC-PROTOCOL 6.1).

  The macOS agent stores `TrackedTimeSpan.client`, `.project` and `.ticket` as
  plain strings and auto-creates them on first use; the server needs foreign
  keys. Both representations travel on the wire, and this module reconciles them
  for client, then project, then ticket - parent before child, because a
  project's id is derived from its client's canonical name.

  The five cases, in the order they are tried:

  1. **`*_id` present and live** - use it, and refresh `*_name` from the row so
     the read side shows the current name rather than stale provenance. A
     tombstoned row with `merged_into_id` is followed exactly one hop.
  2. **`*_id` present but unknown** - keep it as a *deferred reference* and
     report the field in `unresolved_refs`. It is not rejected: references are
     application-level rather than database foreign keys precisely so an
     at-least-once push queue can deliver a span before the project it names.
  3. **`*_id` absent, `*_name` non-empty** - resolve against the canonical-name
     unique index.
  4. **`*_id` absent, name misses** - **auto-vivify** with the deterministic id
     from 3.2, `auto_created: true` and `review_state: needs_review`, returned in
     `side_effects` so the pusher can render the name without waiting for a pull.
  5. **`*_id` absent, `*_name` empty** - a genuinely null reference. Spans with
     no project are legal and roll up under "Unassigned".

  Auto-vivification is deliberate rather than lenient. Rejecting a span because
  its project has not arrived yet would strand a day of offline capture behind
  one missing taxonomy row.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Taxonomy
  alias Timely.Sync.Canon
  alias Timely.Sync.Entities
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  @doc """
  Resolves the client / project / ticket references on a `time_span` payload.

  Returns `{attrs, unresolved_refs, side_effects}` with `*_id` and `*_name`
  filled in, the field names of any deferred references, and any rows vivified
  along the way.
  """
  # ⟦𓂋𓋴𓆑𓋴⟧ resolve_span :: Resolves a time_span's taxonomy references.
  def resolve_span(workspace_id, attrs, ctx) do
    {attrs, unresolved, effects} = resolve_client(workspace_id, attrs, ctx, {[], []})

    {attrs, unresolved, effects} =
      resolve_project(workspace_id, attrs, ctx, {unresolved, effects})

    resolve_ticket(workspace_id, attrs, ctx, {unresolved, effects})
  end

  @doc """
  Resolves the parent references carried by a taxonomy row: a project's client,
  a ticket's client and project. Same five cases, same auto-vivification.
  """
  # ⟦𓊪𓂋𓈖𓏏⟧ resolve_parents :: Resolves a taxonomy row's parent references.
  def resolve_parents(workspace_id, "project", attrs, ctx) do
    {attrs, unresolved, effects} = resolve_client(workspace_id, attrs, ctx, {[], []})
    {attrs, unresolved, effects}
  end

  def resolve_parents(workspace_id, "ticket", attrs, ctx) do
    {attrs, unresolved, effects} = resolve_client(workspace_id, attrs, ctx, {[], []})
    resolve_project(workspace_id, attrs, ctx, {unresolved, effects})
  end

  def resolve_parents(_workspace_id, _kind, attrs, _ctx), do: {attrs, [], []}

  # -- client -----------------------------------------------------------------

  defp resolve_client(workspace_id, attrs, ctx, {unresolved, effects}) do
    if not mentions?(attrs, ["client_id", "client_name"]) do
      {attrs, unresolved, effects}
    else
      do_resolve_client(workspace_id, attrs, ctx, {unresolved, effects})
    end
  end

  defp do_resolve_client(workspace_id, attrs, ctx, {unresolved, effects}) do
    id = get(attrs, "client_id")
    name = get(attrs, "client_name")

    case lookup(Taxonomy.Client, workspace_id, id, fn ->
           by_canonical_client(workspace_id, name)
         end) do
      {:resolved, row} ->
        {attrs |> put("client_id", row.id) |> put("client_name", row.name), unresolved, effects}

      {:deferred, id} ->
        {put(attrs, "client_id", id), unresolved ++ ["client_id"], effects}

      :vivify ->
        case Canon.client_id(workspace_id, name) do
          nil ->
            {attrs |> put("client_id", nil) |> put("client_name", ""), unresolved, effects}

          new_id ->
            row = vivify_client(workspace_id, new_id, name, ctx)

            {attrs |> put("client_id", row.id) |> put("client_name", row.name), unresolved,
             effects ++ [{"client", row}]}
        end

      :absent ->
        {attrs |> put("client_id", nil) |> put("client_name", ""), unresolved, effects}
    end
  end

  # -- project ----------------------------------------------------------------

  defp resolve_project(workspace_id, attrs, ctx, {unresolved, effects}) do
    if not mentions?(attrs, ["project_id", "project_name"]) do
      {attrs, unresolved, effects}
    else
      do_resolve_project(workspace_id, attrs, ctx, {unresolved, effects})
    end
  end

  defp do_resolve_project(workspace_id, attrs, ctx, {unresolved, effects}) do
    id = get(attrs, "project_id")
    name = get(attrs, "project_name")
    client_id = get(attrs, "client_id")
    client_name = get(attrs, "client_name")

    case lookup(Taxonomy.Project, workspace_id, id, fn ->
           by_canonical_project(workspace_id, client_id, name)
         end) do
      {:resolved, row} ->
        {attrs |> put("project_id", row.id) |> put("project_name", row.name), unresolved, effects}

      {:deferred, id} ->
        {put(attrs, "project_id", id), unresolved ++ ["project_id"], effects}

      :vivify ->
        case Canon.project_id(workspace_id, client_name, name) do
          nil ->
            {attrs |> put("project_id", nil) |> put("project_name", ""), unresolved, effects}

          new_id ->
            row = vivify_project(workspace_id, new_id, name, client_id, client_name, ctx)

            {attrs |> put("project_id", row.id) |> put("project_name", row.name), unresolved,
             effects ++ [{"project", row}]}
        end

      :absent ->
        {attrs |> put("project_id", nil) |> put("project_name", ""), unresolved, effects}
    end
  end

  # -- ticket -----------------------------------------------------------------

  defp resolve_ticket(workspace_id, attrs, ctx, {unresolved, effects}) do
    if not mentions?(attrs, ["ticket_id", "ticket_name"]) do
      {attrs, unresolved, effects}
    else
      do_resolve_ticket(workspace_id, attrs, ctx, {unresolved, effects})
    end
  end

  defp do_resolve_ticket(workspace_id, attrs, ctx, {unresolved, effects}) do
    id = get(attrs, "ticket_id")
    name = get(attrs, "ticket_name")
    project_id = get(attrs, "project_id")

    case lookup(Taxonomy.Ticket, workspace_id, id, fn ->
           by_canonical_ticket(workspace_id, project_id, name)
         end) do
      {:resolved, row} ->
        {attrs |> put("ticket_id", row.id) |> put("ticket_name", row.name), unresolved, effects}

      {:deferred, id} ->
        {put(attrs, "ticket_id", id), unresolved ++ ["ticket_id"], effects}

      :vivify ->
        client_name = get(attrs, "client_name")
        project_name = get(attrs, "project_name")

        case Canon.ticket_id(workspace_id, client_name, project_name, name) do
          nil ->
            {attrs |> put("ticket_id", nil) |> put("ticket_name", ""), unresolved, effects}

          new_id ->
            row = vivify_ticket(workspace_id, new_id, name, attrs, ctx)

            {attrs |> put("ticket_id", row.id) |> put("ticket_name", row.name), unresolved,
             effects ++ [{"ticket", row}]}
        end

      :absent ->
        {attrs |> put("ticket_id", nil) |> put("ticket_name", ""), unresolved, effects}
    end
  end

  # -- the five-case decision -------------------------------------------------

  defp lookup(schema, workspace_id, id, by_name) do
    cond do
      present?(id) ->
        case Workspace.fetch_any(schema, workspace_id, id) do
          # Case 1, live.
          %{deleted_at: nil} = row ->
            {:resolved, row}

          # Case 1, tombstoned with a merge pointer: follow exactly one hop and
          # then give up, so a cycle or a chain cannot spin here.
          %{merged_into_id: merged} = _row when not is_nil(merged) ->
            case Workspace.fetch_live(schema, workspace_id, merged) do
              nil -> {:deferred, id}
              row -> {:resolved, row}
            end

          # Tombstoned with nowhere to go, or belonging to another workspace.
          _ ->
            {:deferred, id}
        end

      true ->
        # Cases 3, 4 and 5.
        case by_name.() do
          nil -> :vivify
          :absent -> :absent
          row -> {:resolved, row}
        end
    end
  end

  defp by_canonical_client(workspace_id, name) do
    case Canon.canon(name) do
      "" ->
        :absent

      canonical ->
        Taxonomy.Client
        |> Workspace.scope(workspace_id)
        |> where([c], c.canonical_name == ^canonical and is_nil(c.deleted_at))
        |> Repo.one()
    end
  end

  defp by_canonical_project(workspace_id, client_id, name) do
    case Canon.canon(name) do
      "" ->
        :absent

      canonical ->
        query =
          Taxonomy.Project
          |> Workspace.scope(workspace_id)
          |> where([p], p.canonical_name == ^canonical and is_nil(p.deleted_at))

        # "a null client_id is its own scope" - NULL never equals NULL in a
        # Postgres unique index, so the unscoped case needs `is_nil`, not `==`.
        query =
          if present?(client_id),
            do: where(query, [p], p.client_id == ^client_id),
            else: where(query, [p], is_nil(p.client_id))

        Repo.one(query)
    end
  end

  defp by_canonical_ticket(workspace_id, project_id, name) do
    case Canon.canon(name) do
      "" ->
        :absent

      canonical ->
        query =
          Taxonomy.Ticket
          |> Workspace.scope(workspace_id)
          |> where([t], t.canonical_name == ^canonical and is_nil(t.deleted_at))

        query =
          if present?(project_id),
            do: where(query, [t], t.project_id == ^project_id),
            else: where(query, [t], is_nil(t.project_id))

        Repo.one(query)
    end
  end

  # -- vivification -----------------------------------------------------------

  defp vivify_client(workspace_id, id, name, ctx) do
    insert_vivified(Taxonomy.Client, workspace_id, id, ctx, %{
      name: trimmed(name),
      canonical_name: Canon.canon(name)
    })
  end

  defp vivify_project(workspace_id, id, name, client_id, client_name, ctx) do
    insert_vivified(Taxonomy.Project, workspace_id, id, ctx, %{
      name: trimmed(name),
      canonical_name: Canon.canon(name),
      client_id: nilify(client_id),
      client_name: to_string(client_name || "")
    })
  end

  defp vivify_ticket(workspace_id, id, name, attrs, ctx) do
    insert_vivified(Taxonomy.Ticket, workspace_id, id, ctx, %{
      name: trimmed(name),
      canonical_name: Canon.canon(name),
      client_id: nilify(get(attrs, "client_id")),
      project_id: nilify(get(attrs, "project_id")),
      client_name: to_string(get(attrs, "client_name") || ""),
      project_name: to_string(get(attrs, "project_name") || "")
    })
  end

  # The insert is `ON CONFLICT DO NOTHING` on the deterministic primary key: two
  # devices vivifying the same name in the same instant compute the same id, and
  # the second one simply reads the first one's row rather than failing the push.
  defp insert_vivified(schema, workspace_id, id, ctx, fields) do
    now = ctx.now
    revision = Revisions.allocate!(workspace_id)

    record =
      struct(
        schema,
        Map.merge(fields, %{
          id: id,
          workspace_id: workspace_id,
          auto_created: true,
          # Auto-created rows are review work by construction: the server guessed
          # a name boundary the user never confirmed.
          review_state: "needs_review",
          notes: "",
          created_at: now,
          updated_at: now,
          updated_at_effective: now,
          server_revision: revision,
          origin_device_id: ctx.device_id
        })
      )

    case Repo.insert(record, on_conflict: :nothing) do
      {:ok, %{__meta__: %{state: :loaded}} = inserted} ->
        if Repo.get(schema, id), do: Repo.get(schema, id), else: inserted

      {:ok, inserted} ->
        inserted

      {:error, _changeset} ->
        Workspace.fetch_any(schema, workspace_id, id)
    end
    |> case do
      nil -> Workspace.fetch_any(schema, workspace_id, id)
      row -> row
    end
  end

  @doc "The bucket name a side effect is reported under."
  # ⟦𓋴𓆑𓎡𓈖⟧ side_effect_kind :: Entity kind for a vivified row.
  def side_effect_kind(kind), do: Entities.bucket(kind)

  # Step 5 of 6.1 - "*_id absent and *_name empty means the reference is
  # genuinely null" - is about a client that HAS no reference, not about a
  # payload that never mentions one. Conflating the two makes an ordinary title
  # edit from a client that omits unmentioned fields silently unassign the
  # span's client and project, which is a far worse data loss than the reopen
  # this module's siblings guard against.
  #
  # So: a reference group is resolved only when the payload actually names some
  # part of it. An unmentioned group is left out of `attrs` entirely, and
  # `Ecto.Changeset.cast/3` therefore leaves the stored columns alone - the same
  # merge-only-present-keys rule every other field follows.
  defp mentions?(attrs, keys), do: Enum.any?(keys, &Map.has_key?(attrs, &1))

  defp get(attrs, key), do: Map.get(attrs, key)
  defp put(attrs, key, value), do: Map.put(attrs, key, value)

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(_), do: true

  defp nilify(""), do: nil
  defp nilify(value), do: value

  # The stored `name` keeps the user's spelling; only `canonical_name` is
  # normalized. Whitespace is trimmed because a leading space is never intended.
  defp trimmed(name), do: name |> to_string() |> String.trim()
end
