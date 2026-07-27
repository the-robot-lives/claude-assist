defmodule Timely.Sync.Mutations do
  @moduledoc """
  The push path: `POST /api/v1/sync/mutations`, and with it the whole of
  SYNC-PROTOCOL section 8's 22-row conflict matrix.

  ## Shape

  Every mutation produces exactly one `MutationResult`, and all three statuses
  are terminal for the client's queue:

  - `applied` - processed. Note that "applied" does **not** mean "your version
    won": a mutation that loses last-write-wins is still `applied`, with
    `stale_base: true` and the authoritative row returned, because the mutation
    *was* evaluated and the client's copy is simply superseded (worked example
    T4).
  - `conflict` - the server holds a different authoritative state; adopt the
    returned entity.
  - `rejected` - invalid and will never succeed.

  ## Atomicity

  A non-atomic batch runs each mutation in its own transaction, so one bad
  member cannot undo its neighbours. An `atomic: true` batch runs in a single
  transaction and row 22 applies: if any member is not `applied`, the whole
  batch is rolled back, every result becomes `rejected` / `batch_rolled_back`,
  and the response is `409`. That is what makes split and merge - expressed as
  ordinary create/update/delete mutations sharing a `derived_from_span_ids`
  lineage - land whole or not at all.

  ## Idempotency

  A `mutation_id` already in `applied_mutations` is answered from the ledger
  with `replayed: true`. The **original** result is returned verbatim: the
  server does not re-apply, does not bump `server_revision`, and does not re-run
  duplicate detection. Re-deriving the answer would be wrong, not merely
  wasteful, because the row has usually moved on since.
  """

  import Ecto.Query

  alias Timely.Repo
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Evidence.VisionAnalysis
  alias Timely.Schema.Sync.AppliedMutation
  alias Timely.Schema.Taxonomy
  alias Timely.Sync.Canon
  alias Timely.Sync.Duplicates
  alias Timely.Sync.Entities
  alias Timely.Sync.Policy
  alias Timely.Sync.Resolver
  alias Timely.Sync.Revisions
  alias Timely.Sync.Workspace

  # A mutation whose `updated_at` exceeds receipt by more than this is still
  # applied - rejecting it would strand offline work - but the row is flagged
  # `low_confidence` so a human sees that a device reports impossible times.
  @clock_skew_tolerance_seconds 300

  @max_batch 200
  @max_atomic_batch 50

  @doc """
  Applies a batch of mutations.

  Returns `{:ok, results}` or, for an atomic batch that could not be applied in
  full, `{:conflict, results}` - which the controller renders as `409`.
  """
  # ⟦𓊪𓅱𓋴𓎛⟧ push :: Applies a batch of mutations.
  def push(ctx, mutations) when is_list(mutations) do
    # `server_received_at` is stamped here, at the moment the batch is actually
    # processed, rather than taken from whatever the caller assembled earlier.
    # The clamp in 4.1 is only meaningful against a real receipt time: a `now`
    # captured before the request would clamp every mutation into the past and
    # make live edits lose LWW against rows written since.
    ctx = Map.put(ctx, :now, DateTime.utc_now())

    cond do
      mutations == [] ->
        {:error, :empty_batch}

      length(mutations) > @max_batch ->
        {:error, :batch_too_large}

      ctx.atomic and length(mutations) > @max_atomic_batch ->
        {:error, :batch_too_large}

      ctx.atomic ->
        push_atomic(ctx, mutations)

      true ->
        {:ok, Enum.map(mutations, &apply_isolated(ctx, &1))}
    end
  end

  # Row 22. The transaction is rolled back explicitly so that every write the
  # batch made - rows, revisions, and the ledger entries that would otherwise
  # make a retry look like a replay - is undone together.
  defp push_atomic(ctx, mutations) do
    outcome =
      Repo.transaction(fn ->
        results = Enum.map(mutations, &apply_one(ctx, &1))

        if Enum.all?(results, &(&1["status"] == "applied")) do
          results
        else
          Repo.rollback({:batch_rolled_back, results})
        end
      end)

    case outcome do
      {:ok, results} ->
        {:ok, results}

      {:error, {:batch_rolled_back, results}} ->
        {:conflict, Enum.map(results, &rolled_back/1)}
    end
  end

  defp rolled_back(result) do
    %{
      "mutation_id" => result["mutation_id"],
      "status" => "rejected",
      "reason" => "batch_rolled_back",
      "message" => "another mutation in this atomic batch could not be applied",
      "entity" => nil,
      # Carried through even though the batch wrote nothing, so a client can
      # still route the failure back to the queued mutation it belongs to.
      "entity_kind" => result["entity_kind"],
      "side_effects" => [],
      "replayed" => false,
      "stale_base" => false,
      "unresolved_refs" => []
    }
  end

  # A non-atomic member gets its own transaction. A crash inside one mutation
  # must not take its already-applied neighbours with it, and the ledger write
  # has to commit with the row it describes or a retry would double-apply.
  defp apply_isolated(ctx, mutation) do
    case Repo.transaction(fn -> apply_one(ctx, mutation) end) do
      {:ok, result} ->
        result

      {:error, _reason} ->
        mutation["mutation_id"]
        |> result("rejected", reason: "validation_failed")
        |> tag_entity_kind(mutation)
    end
  end

  # -- one mutation -----------------------------------------------------------

  defp apply_one(ctx, mutation) do
    mutation_id = mutation["mutation_id"]

    case replayed_result(ctx.workspace_id, mutation_id) do
      nil ->
        mutation_id
        |> dispatch(ctx, mutation)
        |> tag_entity_kind(mutation)
        |> record(ctx, mutation)

      recorded ->
        recorded
    end
  end

  # `results` comes back as one flat array, so - unlike `/sync/changes`, where
  # each row sits in a named bucket - nothing about a `MutationResult` says
  # which kind of row `entity` is. Without this a client has to infer the type
  # from the field shape, and the failure mode of guessing wrong is writing a
  # time_span into the clients table.
  #
  # The tag goes on the result envelope rather than inside `entity` for three
  # reasons: it is still present when `entity` is null (every `rejected`
  # result), it leaves the ten entity schemas exactly as the contract defines
  # them, and it matches how `SideEffect` already pairs `entity` (the kind) with
  # `row` (the payload).
  #
  # The echoed row is always the same kind as the mutation that produced it -
  # `applied` returns the row just written, and both `conflict` reasons
  # (`duplicate_name`, `tombstoned`) return a row of the same kind - so this is
  # derivable in one place instead of being threaded through every branch.
  defp tag_entity_kind(result, mutation) do
    kind = mutation["entity"]
    Map.put(result, "entity_kind", if(kind in Entities.kinds(), do: kind, else: nil))
  end

  # The ledger answers a replay verbatim. `replayed: true` is the only field
  # that differs from the original response.
  defp replayed_result(workspace_id, mutation_id) do
    with true <- is_binary(mutation_id) and match?({:ok, _}, Ecto.UUID.cast(mutation_id)),
         %AppliedMutation{result: result} <-
           AppliedMutation
           |> where([m], m.workspace_id == ^workspace_id and m.mutation_id == ^mutation_id)
           |> Repo.one() do
      Map.put(result, "replayed", true)
    else
      _ -> nil
    end
  end

  defp dispatch(mutation_id, ctx, mutation) do
    kind = mutation["entity"]
    op = mutation["op"]
    payload = mutation["payload"] || %{}

    cond do
      not is_binary(mutation_id) or not match?({:ok, _}, Ecto.UUID.cast(mutation_id)) ->
        result(mutation_id, "rejected",
          reason: "validation_failed",
          message: "mutation_id must be a uuid"
        )

      kind not in Entities.kinds() ->
        result(mutation_id, "rejected", reason: "unknown_entity")

      op not in ["create", "update", "delete"] ->
        result(mutation_id, "rejected", reason: "validation_failed", message: "unknown op")

      not valid_id?(payload["id"]) ->
        result(mutation_id, "rejected",
          reason: "validation_failed",
          message: "payload.id must be a uuid"
        )

      # Row 21. A payload that names a different workspace than the request is
      # never a routing accident worth guessing about.
      payload_workspace_mismatch?(payload, ctx.workspace_id) ->
        result(mutation_id, "rejected", reason: "workspace_mismatch")

      # Row 18. Only the subject device may mutate its own row.
      kind == "device" and payload["id"] != ctx.device_id ->
        result(mutation_id, "rejected", reason: "not_device_owner")

      # Row 19.
      kind == "workspace_policy" and not ctx.admin ->
        result(mutation_id, "rejected", reason: "permission_denied")

      # Rows 14 and 15. Append-only entities reject every update. `delete` is
      # still allowed - a tombstone is not a mutation of the row's content, and
      # the censorship cascade depends on being able to lay one.
      op == "update" and Entities.append_only?(kind) ->
        result(mutation_id, "rejected", reason: "immutable_entity")

      op == "delete" ->
        apply_delete(mutation_id, ctx, kind, payload, mutation)

      true ->
        apply_upsert(mutation_id, ctx, kind, payload, mutation)
    end
  end

  # -- delete -----------------------------------------------------------------

  defp apply_delete(mutation_id, ctx, kind, payload, mutation) do
    {:ok, schema} = Entities.schema(kind)
    id = payload["id"]
    existing = Workspace.fetch_any(schema, ctx.workspace_id, id)
    {effective, skewed?} = clamp(payload["updated_at"], ctx.now)

    case existing do
      nil ->
        # Nothing to tombstone. The row was never delivered here, and every
        # NOT NULL column would have to be invented to lay a tombstone anyway.
        # Applied rather than rejected, because a delete for something that does
        # not exist has already achieved what it asked for.
        result(mutation_id, "applied", entity: nil)

      # Row 3. Idempotent, and the earliest `deleted_at` is retained - a second
      # delete must not move the tombstone forward.
      %{deleted_at: deleted_at} when not is_nil(deleted_at) ->
        result(mutation_id, "applied", entity: wire(existing, ctx))

      _ ->
        deleted_at = parse_datetime(payload["deleted_at"]) || effective
        revision = Revisions.allocate!(ctx.workspace_id)

        {1, [updated]} =
          schema
          |> Workspace.scope(ctx.workspace_id)
          |> where([r], r.id == ^id)
          |> select([r], r)
          |> Repo.update_all(
            set: [
              deleted_at: deleted_at,
              updated_at: parse_datetime(payload["updated_at"]) || ctx.now,
              updated_at_effective: effective,
              server_revision: revision,
              origin_device_id: payload["origin_device_id"] || ctx.device_id
            ]
          )

        result(mutation_id, "applied",
          entity: wire(updated, ctx),
          stale_base: skewed? or stale_base?(mutation, existing)
        )
    end
  end

  # -- create / update --------------------------------------------------------

  defp apply_upsert(mutation_id, ctx, kind, payload, mutation) do
    {:ok, schema} = Entities.schema(kind)
    id = payload["id"]
    existing = Workspace.fetch_any(schema, ctx.workspace_id, id)
    {effective, skewed?} = clamp(payload["updated_at"], ctx.now)

    cond do
      # Row 2. The tombstone is absorbing, regardless of timestamps: a device
      # that has not seen the delete must not resurrect the row.
      match?(%{deleted_at: deleted_at} when not is_nil(deleted_at), existing) ->
        result(mutation_id, "conflict",
          reason: "tombstoned",
          entity: wire(existing, ctx),
          message: "the row was deleted; adopt the tombstone"
        )

      true ->
        guard(mutation_id, ctx, kind, payload, mutation, schema, existing, effective, skewed?)
    end
  end

  # Entity-specific guards that run before the generic LWW rule.
  defp guard(mutation_id, ctx, kind, payload, mutation, schema, existing, effective, skewed?) do
    with :ok <- guard_taxonomy(ctx, kind, payload, existing),
         :ok <- guard_span(ctx, kind, payload, mutation, existing) do
      write(mutation_id, ctx, kind, payload, mutation, schema, existing, effective, skewed?)
    else
      {:conflict, reason, row} ->
        result(mutation_id, "conflict", reason: reason, entity: wire(row, ctx))

      {:rejected, reason, message} ->
        result(mutation_id, "rejected", reason: reason, message: message)
    end
  end

  # Rows 12 and 13. The server checks the canonical-name index before minting.
  # Row 12 is a create whose canonical name already belongs to a different id -
  # which happens after a rename, when an offline device vivifies the *new* name
  # and computes a *new* id. Row 13 is the same collision reached by renaming.
  # Both answer `duplicate_name` with the authoritative row, and the client
  # performs a reference rewrite.
  defp guard_taxonomy(ctx, kind, payload, _existing) when kind in ~w(client project ticket) do
    canonical = Canon.canon(payload["name"])

    if canonical == "" do
      # "An empty name after canonicalization is not an entity" (3.3). A create
      # that asks for one is a bug on the client, not a row to mint.
      {:rejected, "validation_failed", "name canonicalizes to empty"}
    else
      case taxonomy_by_canonical(ctx.workspace_id, kind, canonical, payload) do
        # The name is free, or it is already this very row.
        nil ->
          :ok

        %{id: id} = row ->
          if id == payload["id"], do: :ok, else: {:conflict, "duplicate_name", row}
      end
    end
  end

  defp guard_taxonomy(_ctx, _kind, _payload, _existing), do: :ok

  defp guard_span(ctx, "time_span", payload, mutation, existing) do
    with :ok <- guard_locked(ctx, payload, mutation, existing),
         :ok <- guard_reopen(payload, mutation, existing) do
      :ok
    end
  end

  defp guard_span(_ctx, _kind, _payload, _mutation, _existing), do: :ok

  # Row 11. A locked span, or one starting on or before
  # `workspace_policy.locked_through`, rejects updates - unless the mutation
  # also clears the lock and the actor may reopen (US-068).
  #
  # The unlock escape hatch requires a CURRENT `base_revision`, exactly as the
  # reopen guard does. Without it the guard read the payload's intent but never
  # asked whether the actor had actually seen the lock, so an admin whose copy
  # predated the approval could clear it by accident and nothing would catch the
  # wrong guess. That asymmetry is why `locked_at` ended up on every client's
  # never-send list, which in turn made US-068's deliberate reopen inexpressible
  # from any native surface.
  #
  # Deliberate unlock and accidental unlock look identical in the payload. The
  # only thing that separates them is whether the actor could see what they were
  # undoing - the same reasoning, and the same discriminator, as rows 6 and 7.
  defp guard_locked(ctx, payload, mutation, existing) do
    locked_through = Policy.locked_through(ctx.workspace_id)

    locked? =
      cond do
        existing == nil -> false
        existing.locked_at != nil -> true
        locked_through == nil -> false
        true -> DateTime.compare(existing.start_at, locked_through) != :gt
      end

    clearing_lock? = Map.has_key?(payload, "locked_at") and payload["locked_at"] == nil
    current_base? = existing != nil and mutation["base_revision"] == existing.server_revision

    cond do
      not locked? ->
        :ok

      clearing_lock? and ctx.admin and current_base? ->
        :ok

      clearing_lock? and ctx.admin ->
        {:rejected, "locked_day",
         "unlocking requires a current base_revision; pull before reopening an approved day"}

      true ->
        {:rejected, "locked_day", "the span is locked or falls in a locked range"}
    end
  end

  # Rows 6 and 7. Reopening a closed span is legitimate when the actor can
  # currently see that it is closed, and forbidden when they cannot: a closed
  # span is evidence, and a device that has not seen the close must not undo it.
  # `base_revision` is the only thing that separates the two cases, which is why
  # it is decisive here and merely advisory everywhere else.
  defp guard_reopen(payload, mutation, existing) do
    # The wire key is `end`, not `end_at` - the rename to the column name does
    # not happen until `Entities.payload_to_attrs/2` runs, well after this
    # guard. Checking the column name here would silently never match, and
    # every stale reopen would be waved through.
    reopening? =
      existing != nil and existing.end_at != nil and
        Map.has_key?(payload, "end") and payload["end"] == nil

    cond do
      not reopening? -> :ok
      mutation["base_revision"] == existing.server_revision -> :ok
      true -> {:rejected, "span_reopen_forbidden", "a closed span cannot be reopened from a stale base"}
    end
  end

  # -- the write --------------------------------------------------------------

  defp write(mutation_id, ctx, kind, payload, mutation, schema, existing, effective, skewed?) do
    attrs = Entities.payload_to_attrs(kind, payload)

    {attrs, unresolved, effects} = resolve_refs(ctx, kind, attrs)

    stale? = skewed? or stale_base?(mutation, existing)

    # Derived once and used for BOTH storage and adjudication. Substituting in
    # one place and not the other made the stored value and the adjudicating
    # value two different answers to "which device authored this row" for a
    # single write.
    origin_device_id = payload["origin_device_id"] || ctx.device_id

    # Rule 1 and rule 4 in one place: a create for an existing id is just an
    # update, and an update that loses LWW leaves the row alone.
    if existing != nil and not wins?(effective, origin_device_id, existing) do
      result(mutation_id, "applied",
        entity: wire(existing, ctx),
        stale_base: true,
        unresolved_refs: unresolved,
        side_effects: side_effects(effects, ctx)
      )
    else
      revision = Revisions.allocate!(ctx.workspace_id)

      attrs =
        attrs
        |> Map.merge(%{
          "id" => payload["id"],
          "workspace_id" => ctx.workspace_id,
          "created_at" =>
            (existing && existing.created_at) || parse_datetime(payload["created_at"]) || ctx.now,
          "updated_at" => parse_datetime(payload["updated_at"]) || ctx.now,
          "updated_at_effective" => effective,
          "server_revision" => revision,
          "deleted_at" => nil,
          "origin_device_id" => origin_device_id
        })
        |> derive_server_owned(ctx, kind, existing)

      base = existing || struct(schema)

      # Row 11's escape hatch: an authorised actor who clears the lock reopens an
      # approved day, which is an auditable event rather than a silent edit.
      flags = %{
        skewed: skewed?,
        unresolved: unresolved,
        reopened_after_approval:
          existing != nil and Map.get(existing, :locked_at) != nil and
            Map.has_key?(payload, "locked_at") and payload["locked_at"] == nil
      }

      changeset =
        base
        |> schema.changeset(attrs)
        # Ids are client-minted and globally unique, so the primary key can only
        # collide when the id already exists in *another* workspace - which
        # `Workspace.fetch_any/3` cannot see, so this path looks like a create
        # right up until the insert. Declaring the constraint turns a raised
        # Ecto.ConstraintError (a 500, and a probe that reveals another tenant's
        # ids exist) into an ordinary rejected result.
        |> Ecto.Changeset.unique_constraint(:id, name: "#{schema.__schema__(:source)}_pkey")

      # `mode: :savepoint` matters as much as the constraint declaration above.
      # A constraint violation aborts the enclosing Postgres transaction, and
      # every later statement in it - including the ledger write that records
      # this mutation's terminal result - fails with 25P02. The savepoint
      # confines the failure to this one statement.
      case Repo.insert_or_update(changeset, mode: :savepoint) do
        {:ok, row} ->
          {row, extra_effects} = post_write(ctx, kind, row, flags)

          result(mutation_id, "applied",
            entity: wire(row, ctx),
            stale_base: stale?,
            unresolved_refs: unresolved,
            side_effects: side_effects(effects ++ extra_effects, ctx)
          )

        {:error, changeset} ->
          if Keyword.has_key?(changeset.errors, :id) do
            result(mutation_id, "rejected",
              reason: "workspace_mismatch",
              message: "that id already exists in another workspace"
            )
          else
            result(mutation_id, "rejected",
              reason: "validation_failed",
              message: changeset_message(changeset)
            )
          end
      end
    end
  end

  # Rule 1's comparison and its tie-break: on equal `updated_at_effective`, the
  # lexically greater `origin_device_id` wins.
  #
  # The incoming side MUST be the *derived* origin - the same value `write/9`
  # stores - and never the raw payload. The reason is §8.1's own justification
  # for choosing this tie-break at all: "a value both sides already have, so
  # every client that sees the same two versions computes the same winner
  # without asking the server". What a client sees is the **stored**
  # `origin_device_id` it pulled; it never sees another device's request body.
  # Adjudicating on the raw payload would therefore compare something no client
  # can observe, and a client that omitted the field would compare `""` against
  # a real id and lose every tie - so two clients with different serialization
  # habits would compute different winners from the same two versions, which is
  # precisely the determinism the rule exists to provide.
  defp wins?(effective, origin_device_id, existing) do
    case DateTime.compare(effective, existing.updated_at_effective) do
      :gt -> true
      :lt -> false
      :eq -> to_string(origin_device_id || "") >= to_string(existing.origin_device_id || "")
    end
  end

  defp resolve_refs(ctx, "time_span", attrs), do: Resolver.resolve_span(ctx.workspace_id, attrs, ctx)

  defp resolve_refs(ctx, kind, attrs) when kind in ~w(project ticket),
    do: Resolver.resolve_parents(ctx.workspace_id, kind, attrs, ctx)

  defp resolve_refs(_ctx, _kind, attrs), do: {attrs, [], []}

  # Fields the client may not set. `canonical_name` is derived rather than
  # trusted; `raw_response` is gated (10.3); `upload_state` and every `blob_*`
  # field are server-owned (row 17) and are simply carried forward.
  defp derive_server_owned(attrs, _ctx, kind, existing) when kind in ~w(client project ticket) do
    Map.put(attrs, "canonical_name", Canon.canon(attrs["name"] || (existing && existing.name)))
  end

  defp derive_server_owned(attrs, ctx, "vision_analysis", _existing) do
    if Policy.raw_response_allowed?(ctx.workspace_id) do
      Map.put(attrs, "raw_response_withheld", is_nil(attrs["raw_response"]))
    else
      # Withheld, not absent: null plus the flag distinguishes "policy
      # suppressed this" from "the source never had it".
      attrs
      |> Map.put("raw_response", nil)
      |> Map.put("raw_response_withheld", true)
    end
  end

  defp derive_server_owned(attrs, _ctx, "screenshot", existing) do
    Map.merge(attrs, %{
      "upload_state" => (existing && existing.upload_state) || "local_only",
      "blob_storage_key" => existing && existing.blob_storage_key,
      "blob_content_hash" => existing && existing.blob_content_hash,
      "blob_byte_size" => existing && existing.blob_byte_size,
      "blob_uploaded_at" => existing && existing.blob_uploaded_at,
      "censored" => (existing && existing.censored) || false
    })
  end

  defp derive_server_owned(attrs, _ctx, "time_span", existing) do
    attrs
    |> Map.put("canonical_title", Canon.canon(attrs["title"] || (existing && existing.title)))
    |> Map.put("review_reasons", (existing && existing.review_reasons) || [])
  end

  defp derive_server_owned(attrs, _ctx, _kind, _existing), do: attrs

  # Everything that happens *because of* a write rather than as part of it.
  defp post_write(ctx, "time_span", row, flags) do
    row =
      if flags.skewed do
        # Row 5. The clamp already fixed the ordering; the flag is so a human
        # sees that a device is reporting impossible times.
        Duplicates.raise_flag(
          ctx.workspace_id,
          row,
          "low_confidence",
          nil,
          ctx,
          "updated_at was more than #{@clock_skew_tolerance_seconds}s ahead of receipt"
        )
      else
        row
      end

    row =
      if flags.unresolved == [] do
        row
      else
        # 6.1 step 2. The write succeeded and the reference is deferred; the
        # flag is what surfaces it if it is still dangling a day later.
        Duplicates.raise_flag(
          ctx.workspace_id,
          row,
          "unresolved_reference",
          nil,
          ctx,
          Enum.join(flags.unresolved, ", ")
        )
      end

    row =
      if flags.reopened_after_approval do
        Duplicates.raise_flag(ctx.workspace_id, row, "reopened_after_approval", nil, ctx)
      else
        row
      end

    # Rows 9 and 10.
    {Duplicates.scan(ctx.workspace_id, row, ctx), []}
  end

  # Row 16. A censorship record is an assertion, and the cascade is what makes
  # the macOS agent's local hard-delete expressible in a protocol that never
  # hard-deletes.
  defp post_write(ctx, "censored_screenshot", row, _flags) do
    {row, cascade_censorship(ctx, row)}
  end

  defp post_write(_ctx, _kind, row, _flags), do: {row, []}

  defp cascade_censorship(ctx, censored) do
    now = ctx.now

    screenshot =
      Screenshot
      |> Workspace.scope(ctx.workspace_id)
      |> where([s], s.id == ^censored.screenshot_id and is_nil(s.deleted_at))
      |> Repo.one()

    analyses =
      VisionAnalysis
      |> Workspace.scope(ctx.workspace_id)
      |> where([v], v.screenshot_id == ^censored.screenshot_id and is_nil(v.deleted_at))
      |> Repo.all()

    screenshot_effects =
      case screenshot do
        nil ->
          []

        row ->
          # The bytes go, the metadata row stays: the timeline must not develop
          # holes just because one capture was censored.
          Timely.Sync.Blobs.purge(row)

          revision = Revisions.allocate!(ctx.workspace_id)

          {1, [updated]} =
            Screenshot
            |> Workspace.scope(ctx.workspace_id)
            |> where([s], s.id == ^row.id)
            |> select([s], s)
            |> Repo.update_all(
              set: [
                deleted_at: now,
                censored: true,
                upload_state: "purged",
                blob_storage_key: nil,
                blob_content_hash: nil,
                blob_byte_size: nil,
                blob_uploaded_at: nil,
                updated_at: now,
                updated_at_effective: now,
                server_revision: revision
              ]
            )

          [{"screenshot", updated}]
      end

    analysis_effects =
      Enum.map(analyses, fn analysis ->
        revision = Revisions.allocate!(ctx.workspace_id)

        {1, [updated]} =
          VisionAnalysis
          |> Workspace.scope(ctx.workspace_id)
          |> where([v], v.id == ^analysis.id)
          |> select([v], v)
          |> Repo.update_all(
            set: [
              deleted_at: now,
              raw_response: nil,
              raw_response_withheld: true,
              updated_at: now,
              updated_at_effective: now,
              server_revision: revision
            ]
          )

        {"vision_analysis", updated}
      end)

    screenshot_effects ++ analysis_effects
  end

  # -- ledger -----------------------------------------------------------------

  defp record(result, ctx, mutation) do
    # A rejected mutation is recorded too. It is terminal, so a retry must get
    # the same terminal answer rather than a fresh evaluation against a row that
    # has since changed.
    %AppliedMutation{}
    |> AppliedMutation.changeset(%{
      "mutation_id" => result["mutation_id"],
      "workspace_id" => ctx.workspace_id,
      "device_id" => ctx.device_id,
      "status" => result["status"],
      "reason" => result["reason"],
      "entity_kind" => mutation["entity"],
      "entity_id" => get_in(mutation, ["payload", "id"]),
      "resulting_server_revision" => get_in(result, ["entity", "server_revision"]),
      "result" => result,
      "applied_at" => ctx.now
    })
    # Savepointed for the same reason as the row write: the losing side of two
    # concurrent deliveries hits the unique index here and must still be able to
    # read its answer out of the ledger afterwards.
    |> Repo.insert(mode: :savepoint)
    |> case do
      {:ok, _} ->
        result

      {:error, _changeset} ->
        # Two concurrent deliveries of the same batch: the loser's insert fails
        # on the unique index and is answered from the log, which is exactly the
        # guarantee 9.1 asks the index to provide.
        replayed_result(ctx.workspace_id, result["mutation_id"]) || result
    end
  end

  # -- helpers ----------------------------------------------------------------

  defp taxonomy_by_canonical(workspace_id, "client", canonical, _payload) do
    Taxonomy.Client
    |> Workspace.scope(workspace_id)
    |> where([c], c.canonical_name == ^canonical and is_nil(c.deleted_at))
    |> Repo.one()
  end

  defp taxonomy_by_canonical(workspace_id, "project", canonical, payload) do
    query =
      Taxonomy.Project
      |> Workspace.scope(workspace_id)
      |> where([p], p.canonical_name == ^canonical and is_nil(p.deleted_at))

    case payload["client_id"] do
      nil -> where(query, [p], is_nil(p.client_id))
      client_id -> where(query, [p], p.client_id == ^client_id)
    end
    |> Repo.one()
  end

  defp taxonomy_by_canonical(workspace_id, "ticket", canonical, payload) do
    query =
      Taxonomy.Ticket
      |> Workspace.scope(workspace_id)
      |> where([t], t.canonical_name == ^canonical and is_nil(t.deleted_at))

    case payload["project_id"] do
      nil -> where(query, [t], is_nil(t.project_id))
      project_id -> where(query, [t], t.project_id == ^project_id)
    end
    |> Repo.one()
  end

  # 4.1. `updated_at_effective = min(updated_at, server_received_at)`. Without
  # it a device whose clock is set to 2031 wins every conflict for five years,
  # and the clamp cannot be gamed by a laggard either: work composed offline on
  # Monday and pushed on Friday is clamped to Friday, which is when the rest of
  # the system first learned of it.
  defp clamp(updated_at, now) do
    case parse_datetime(updated_at) do
      nil ->
        {now, false}

      value ->
        skewed? = DateTime.diff(value, now, :second) > @clock_skew_tolerance_seconds
        effective = if DateTime.compare(value, now) == :gt, do: now, else: value
        {effective, skewed?}
    end
  end

  defp stale_base?(%{"base_revision" => base}, existing)
       when is_integer(base) and not is_nil(existing) do
    base < existing.server_revision
  end

  defp stale_base?(_mutation, _existing), do: false

  defp payload_workspace_mismatch?(payload, workspace_id) do
    case payload["workspace_id"] do
      nil -> false
      value -> to_string(value) != to_string(workspace_id)
    end
  end

  defp side_effects(effects, ctx) do
    Enum.map(effects, fn {kind, row} ->
      %{"entity" => kind, "row" => wire(row, ctx)}
    end)
  end

  defp wire(nil, _ctx), do: nil
  defp wire(row, ctx), do: Entities.wire(row, blob_url_builder: ctx[:blob_url_builder])

  defp result(mutation_id, status, opts) do
    %{
      "mutation_id" => mutation_id,
      "status" => status,
      # Always present in the shape, even before `tag_entity_kind/2` fills it,
      # so a client never has to distinguish "absent" from "null".
      "entity_kind" => Keyword.get(opts, :entity_kind),
      "reason" => Keyword.get(opts, :reason),
      "message" => Keyword.get(opts, :message),
      "entity" => Keyword.get(opts, :entity),
      "side_effects" => Keyword.get(opts, :side_effects, []),
      "replayed" => false,
      "stale_base" => Keyword.get(opts, :stale_base, false),
      "unresolved_refs" => Keyword.get(opts, :unresolved_refs, [])
    }
  end

  defp valid_id?(value) when is_binary(value), do: match?({:ok, _}, Ecto.UUID.cast(value))
  defp valid_id?(_), do: false

  defp parse_datetime(nil), do: nil
  defp parse_datetime(%DateTime{} = value), do: value

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
    |> Enum.join("; ")
  end
end
