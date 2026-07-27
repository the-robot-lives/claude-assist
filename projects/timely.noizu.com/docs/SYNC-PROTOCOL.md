# Timely Sync Protocol

**Domain:** timely.noizu.com
**Status:** normative draft
**Version:** 1.0.0-draft.1
**Last updated:** 2026-07-27
**Machine-readable contract:** [`apps/shared/contracts/timely-api.yaml`](../apps/shared/contracts/timely-api.yaml)

Timely runs on three independently written clients and one server. The macOS
agent captures, the iOS and Android apps review and correct, and the Phoenix
backend arbitrates. None of them can be trusted to be online, and only one of
them holds the screenshots. This document is the contract that keeps them
consistent anyway.

Where this document and the OpenAPI file disagree, this document governs intent
and the OpenAPI file governs wire shape.

Requirement keywords (MUST, MUST NOT, SHOULD, MAY) are used in the RFC 2119
sense.

## 1. Roles

| Actor | Captures | Reviews | Holds image bytes |
|-------|----------|---------|-------------------|
| macOS agent | Yes - the only capture agent | Yes | Yes |
| iOS companion | No | Yes | No |
| Android companion | No | Yes | No |
| Web dashboard | No | Yes | Only if uploaded |
| Phoenix backend | No | Arbitrates, flags | Only if uploaded |

Companions perform day review, idle prompts, interval correction (split, merge,
reassign, retitle, rebill), manual entry, and reports. Companions MUST NOT
capture screenshots and MUST NOT run background capture. A companion that
receives a capture-related mutation from a user gesture is doing correction, not
capture, and that distinction is enforced only by the client - the server does
not police it beyond `device.is_capture_agent`.

## 2. Design Commitments

1. **Offline is the normal case, not the error case.** Every client can create,
   edit, and delete for days without a network and converge afterward.
2. **No write requires a server round-trip to obtain an identity.** All primary
   keys are minted locally.
3. **Ordering is server-assigned, never wall-clock.** Client clocks are wrong.
4. **Nothing is destroyed.** Deletes are tombstones. Merges leave pointers.
5. **The server flags; the user resolves.** Suspected duplicates and billing
   overlaps are surfaced as review work, never silently reconciled.
6. **Image bytes stay put by default.** A client that never uploads a byte is
   fully functional.

## 3. Identity

### 3.1 Key generation

All primary keys are UUIDs, encoded as lowercase canonical strings.

| Entity | UUID version | Rationale |
|--------|--------------|-----------|
| `time_span` | v7 | Event-like. Two devices never mean "the same span". |
| `screenshot` | v7 | Event-like, single-origin. |
| `vision_analysis` | v7 | Append-only event. |
| `censored_screenshot` | v7 | Append-only event. |
| `device` | v7 | One per install. |
| `client` | **v5** | Name-keyed. See 3.2. |
| `project` | **v5** | Name-keyed. |
| `ticket` | **v5** | Name-keyed. |
| `user_settings` | **v5** | Singleton per (workspace, user). |
| `workspace_policy` | n/a | Equals `workspace_id`. |
| `mutation_id` | v7 | Time-ordered idempotency key. |

UUIDv7 is preferred for event-like entities because its leading timestamp makes
primary-key index inserts append-mostly on the server, which matters once a
workspace holds hundreds of thousands of spans.

### 3.2 Deterministic ids for name-keyed entities

The macOS model refers to clients, projects, and tickets by **name string** and
auto-creates them on first use. If two offline devices both auto-create
"Acme / Redesign", random ids produce two rows for one thing.

Therefore taxonomy ids are derived, not random:

```
namespace   = workspace_id                      (as a UUID namespace)
client_id   = uuidv5(namespace, "client:"  + canon(name))
project_id  = uuidv5(namespace, "project:" + canon(client_name) + "/" + canon(name))
ticket_id   = uuidv5(namespace, "ticket:"  + canon(client_name) + "/" + canon(project_name) + "/" + canon(name))
```

Two devices that independently vivify the same name while offline compute the
**same id**, so their creates merge into one row on arrival with no coordination.
This is the single most important trick in the protocol.

### 3.3 `canon()` - canonical name normalization

`canon(s)` MUST be implemented identically on the server, in Swift, and in
Kotlin. Any divergence produces duplicate taxonomy rows, silently.

1. **Strip** every code point in this enumerated set: U+00AD, U+200B, U+200E,
   U+200F, U+202A-U+202E, U+2066-U+2069, U+FEFF. These are invisible formatting
   noise that survives copy-paste. U+200C (ZWNJ) and U+200D (ZWJ) are
   deliberately **not** stripped - they are semantically significant in Indic and
   Persian text and in emoji ZWJ sequences.
2. **NFKC** normalization.
3. **Normalize quotation marks and apostrophes** to their ASCII equivalents:
   map U+2018, U+2019, U+201A, U+201B, and U+02BC to U+0027 (`'`), and map
   U+201C, U+201D, U+201E, and U+201F to U+0022 (`"`). This step MUST run
   **after** NFKC (step 2), not before: U+0149 LATIN SMALL LETTER N PRECEDED BY
   APOSTROPHE NFKC-decomposes to U+02BC + U+006E, so a pre-NFKC mapping would
   leave a stray U+02BC behind. U+0149 is the only code point in Unicode that
   NFKC maps into this target set, and it is pinned by a dedicated fixture case
   (`canon-052`, "ŉuit Shift"). Steps 3 and 4 operate on disjoint code point
   sets, so their relative order with respect to each other is free - only
   their order relative to step 2 matters. The set is fixed and closed: it
   covers what a keyboard or autocorrect substitutes **in place of** the plain
   ASCII key (iOS emits U+2019 where a desktop keyboard emits U+0027), not
   general punctuation folding - "Acme, Inc." and "Acme Inc" remain different
   clients, as do "Acme-Corp" and "Acme Corp".
4. Replace every code point in the Unicode `White_Space=Yes` set with U+0020.
   The set is enumerated explicitly in the fixture file rather than left to each
   runtime's `isWhitespace` predicate, which vary. Note that NFKC does not map
   U+1680 OGHAM SPACE MARK, so this step is not redundant.
5. Collapse runs of U+0020 to one; trim leading and trailing U+0020.
6. **Lowercase, locale-independent**: `String.downcase/1` (Elixir),
   `.lowercased()` (Swift), `.lowercase(Locale.ROOT)` (Kotlin). Never a
   locale-sensitive lowercase - a Turkish locale maps `I` to dotless `ı` and
   forks the workspace.
7. Map U+03C2 GREEK SMALL LETTER FINAL SIGMA to U+03C3. Java, Swift, and Python
   apply the Unicode `Final_Sigma` context rule during lowercasing and produce
   `ς`; Elixir's `:default` mode does not and produces `σ`. This step makes all
   four converge.
8. **NFC** normalization, to recompose anything the case mapping decomposed.

This is *lowercase*, not Unicode case folding. Case folding would be more
robust - it maps `ß` to `ss` and handles final sigma natively - but none of
Elixir, Swift, or Kotlin exposes case folding, so lowercase is the only rule all
three can implement identically without shipping a custom table. The cost is
recorded in section 13.

Diacritics are **not** folded: "Munoz" and "Muñoz" are different clients -
deliberate, since they are usually different names. Quotation marks and
apostrophes, by contrast, **are** normalized (step 3): "Bob's Diner" typed with
a plain ASCII apostrophe and "Bob’s Diner" typed with the iOS-autocorrect U+2019
RIGHT SINGLE QUOTATION MARK converge on the same client id. This is
deliberately narrower than general punctuation folding, not a relaxation of it -
"Acme, Inc." and "Acme Inc" remain different clients.

Every rule above is pinned by an executable fixture - see section 14.

The canonical form is stored as `canonical_name` and carries a unique index:

| Entity | Unique index |
|--------|--------------|
| `client` | `(workspace_id, canonical_name)` |
| `project` | `(workspace_id, client_id, canonical_name)` - a null `client_id` is its own scope |
| `ticket` | `(workspace_id, project_id, canonical_name)` |

An empty name after canonicalization is not an entity. The macOS agent already
skips empty strings when upserting; the server MUST likewise treat `""` as "no
reference" rather than creating a row named `""`.

## 4. The Sync Envelope

Every syncable row carries:

| Field | Type | Owner | Meaning |
|-------|------|-------|---------|
| `id` | uuid | client | Primary key, minted locally. |
| `workspace_id` | uuid | client | Tenancy scope. Equals the scaffold's organization id. |
| `created_at` | timestamp | client | Client wall clock. **Informational only.** |
| `updated_at` | timestamp | client | Client wall clock at last local edit. Advisory LWW input. |
| `server_revision` | int64 | **server** | Monotonic **per workspace**. The cursor. |
| `deleted_at` | timestamp? | client | Soft-delete tombstone. Never hard-deleted inside the horizon. |
| `origin_device_id` | uuid? | client | Last authoring device. Also the LWW tie-break key. |

Clients MUST persist all seven fields locally. A client that drops
`server_revision` cannot resume a cursor and will re-bootstrap forever.

### 4.1 Clock clamping

The server computes, on every write:

```
updated_at_effective = min(payload.updated_at, server_received_at)
```

and compares `updated_at_effective`, not `updated_at`, during conflict
resolution. A device whose clock is set to 2031 would otherwise win every
conflict for the next five years. The clamp cannot be gamed by a laggard either:
a mutation composed offline on Monday and pushed on Friday is clamped to Friday,
which is exactly the moment the rest of the system first learned of it.

A mutation whose `updated_at` exceeds `server_received_at + 300s` is still
applied (rejecting it would strand offline work) but the result carries
`stale_base: true` and a `low_confidence` review flag is raised on the row so a
human sees that a device is reporting impossible times.

## 5. The Cursor Is a Revision, Not a Timestamp

`GET /api/v1/sync/changes?since=<rev>` uses the `server_revision` watermark.

**Why not `?since=<timestamp>`:**

1. **Client clock skew.** Every client would be asking "what changed since a
   moment I made up". A client five minutes fast permanently skips five minutes
   of history; a client five minutes slow re-downloads forever.
2. **Commit-visibility races.** Even with a perfect server clock, if a row's
   timestamp is stamped at statement time but the transaction commits later,
   a puller can read past that timestamp before the row becomes visible - and
   then never see it again. This is the classic silent-data-loss bug in
   timestamp-cursored sync, and it does not announce itself; it just quietly
   drops rows under load.
3. **Ties.** Two rows written in the same millisecond cannot be paged apart.
4. **Time is not monotonic.** NTP steps, DST, VM suspend, laptop sleep, travel.

`server_revision` is assigned from a per-workspace sequence **inside the same
transaction that publishes the row**, so revision order equals commit order.
Two additional server obligations follow:

- `next_cursor` MUST NOT advance past the highest **gap-free committed**
  revision. If revisions 100 and 102 are committed but 101 is still in flight,
  the page ends at 100. Implementations using a Postgres sequence must account
  for concurrent transactions holding lower values (`pg_snapshot_xmin` on the
  current snapshot, or a small watermark-lag window, are both acceptable).
- Revisions are per workspace, not global. A shared global sequence would leak
  workspace write volume and would make the watermark useless after a quiet
  tenant sits behind a noisy one.

### 5.1 Tombstone horizon

Tombstones are retained for at least **90 days**. Every changes response returns
`tombstone_horizon_revision`. A client whose `since` is below the horizon
receives `410 cursor_too_old`, discards its mirror of server state, and
re-bootstraps from `since=0`. **Unpushed local mutations survive a
re-bootstrap** - the push queue is separate from the mirror and is replayed
after the bootstrap completes.

## 6. Name to ID Resolution

This is the genuine impedance mismatch in Timely. The macOS agent stores
`TrackedTimeSpan.client`, `.project`, `.ticket` as plain strings; the server
needs foreign keys. Both representations travel on the wire.

`time_span` carries `client_id` / `project_id` / `ticket_id` **and**
`client_name` / `project_name` / `ticket_name`.

### 6.1 Server resolution algorithm

This algorithm runs for a client/project/ticket reference group **only when the
payload mentions it** - that is, only when at least one of `*_id` or `*_name` is
a key actually present in the payload (`Resolver.mentions?/2`). On an update
where the payload contains neither key for a group, the group is not mentioned
and the row's existing reference is left untouched, full stop - the steps below
never run for it. Conflating "not mentioned" with "mentioned and empty" here was
a real defect (see §8.2's note on presence-sensitivity): it made an ordinary
title edit silently unassign a span's client and project. The five steps below
now describe only the mentioned case.

For each mentioned group among client, then project, then ticket, in that
order (parent before child), on every `time_span` create or update:

1. **`*_id` present and live in this workspace** - use it. Store `*_name` as
   provenance only; the read-side `*_name` is refreshed from the referenced row.
   If the row is tombstoned but has `merged_into_id`, follow the pointer (one
   hop, then give up).

2. **`*_id` present but unknown** - do **not** reject. Store the id as a
   *deferred reference*. The result carries
   `unresolved_refs: ["project_id"]`. References are application-level, not
   database-level foreign keys, precisely so that an at-least-once push queue can
   deliver a span before the project that it names.
   A reference still dangling after 24 hours raises an `unresolved_reference`
   review flag on the span.

3. **`*_id` absent, `*_name` present and non-empty after `canon()`** - resolve by
   canonical name against the unique index. On a hit, use that id.

4. **`*_id` absent, `*_name` present but misses** - **auto-vivify**. The server
   creates the row with the deterministic id from 3.2, `auto_created: true`, and
   `review_state: needs_review`. The created row is returned in the mutation
   result's `side_effects` so the pushing client does not have to wait for the
   next pull to render a project name.

5. **`*_id` absent, `*_name` present and empty** - the reference is deliberately
   cleared. This is a client that mentioned the group and said nothing is there
   - distinct from the group not being mentioned at all (handled above, before
   step 1 ever runs). Spans with no project are legal and roll up under
   "Unassigned".

Auto-vivification is deliberate. Rejecting a span because its project has not
arrived yet would strand a day of offline capture behind one missing taxonomy
row, and the macOS agent has always created these implicitly.

A client that wants to genuinely clear a reference on update must therefore
send an explicit empty marker for the group (an empty `*_name` and no `*_id`,
or - resolved server-side - however the client models "unassign") rather than
simply omitting both keys, which now means "I have no information about this
field," not "there is nothing here." See §8.2 for the general presence-
sensitivity rule this is one instance of.

### 6.2 Client-side minting and the duplicate-name conflict

A client MAY mint taxonomy rows itself (the macOS agent does, on every span
creation). When it does, it MUST use the deterministic id from 3.2.

A client-minted create can still collide, in exactly one way: **rename**. If
"Acme" was renamed to "Acme Corp" on the server, an offline device that vivifies
the *new* name computes a *new* id, which is a duplicate.

The server catches this because it checks the canonical-name index before
minting. The create returns:

```
status: conflict
reason: duplicate_name
entity: <the existing authoritative row>
```

The client MUST then perform a **reference rewrite**:

1. Adopt the returned row.
2. Rewrite every local reference from the rejected id to the returned id.
3. Delete the local orphan.
4. Re-push any spans whose `project_id` changed as ordinary updates with fresh
   `mutation_id`s.

The reverse direction is safe with no special handling: a stale device that
vivifies the *old* name computes the *old* id, which still exists (ids are
stable across renames), so the mint is an idempotent no-op that lands on the
renamed row.

### 6.3 Merge and `merged_into_id`

Merging duplicate taxonomy rows (US-085) sets `merged_into_id` on the loser and
tombstones it. The winner absorbs nothing automatically - spans keep pointing at
the loser id until they are individually repointed, and readers follow
`merged_into_id` one hop. This keeps merge reversible and keeps the audit trail
intact.

### 6.4 Migration of an existing macOS local store

The macOS agent's `timely-state.json` predates all of this. On first sync:

1. For every `ClientRecord` / `ProjectRecord` / `TicketRecord`, discard the
   locally stored random `UUID` and recompute the deterministic id from 3.2.
   Those local ids were never referenced by anything - spans reference names -
   so this rewrite is lossless.
2. For every `TrackedTimeSpan`, populate `client_name` / `project_name` /
   `ticket_name` from the existing string fields and leave `*_id` null. Let the
   server resolve.
3. Backfill the envelope: `created_at = start`, `updated_at = end ?? start`,
   `server_revision = 0`, `deleted_at = null`,
   `origin_device_id = <this device>`. The macOS model has no per-entity
   timestamps, so this is a best-effort reconstruction; it is accurate enough
   because a first sync has no concurrent writer to lose to.
4. Push in dependency order: clients, projects, tickets, spans, screenshots,
   vision analyses, censored screenshots.
5. Mark the local store `migrated_to_sync_v1` so the rewrite never runs twice.

## 7. The Sync Loop

### 7.1 Pull

```
cursor = local.watermark            # 0 to bootstrap
loop:
  r = GET /api/v1/sync/changes?workspace_id=W&since=cursor&limit=500
  apply(r.changes)                  # including tombstones
  cursor = r.next_cursor
  persist(cursor)                   # atomically with the applied rows
  until r.has_more == false
```

- The watermark and the rows it covers MUST be persisted in one local
  transaction. Persisting the cursor first loses data on crash; persisting the
  rows first only costs a replay, which is harmless because apply is idempotent.
- Applying a change to a row with unpushed local edits: the local edit wins in
  the UI until it is pushed and answered. Clients MUST keep the server's version
  alongside (a "shadow") so `base_revision` can be reported accurately.
- Tombstones MUST be applied even for rows the client has never seen (no-op).

**Why this fires so readily - it is the ordinary path, not an edge case.**
Local-store LWW compares `server_revision` before it ever looks at a timestamp:
if the incoming row's `server_revision` differs from what is stored, the higher
one wins outright and the timestamp/tombstone comparison never runs (confirmed
against `TimelyLocalStore.shouldReplace`, the first branch). `server_revision`
is a single counter per workspace that every mutation from every device and
every entity increments, so a client that has anything queued will see an
incoming row's revision jump ahead of its own local watermark the moment
**anyone** in the workspace does anything at all - not only when the two
devices are editing the same row at the same moment. Read literally, "apply a
change to a row with unpushed local edits" sounds like it describes a rare
race between two concurrent edits. It does not: it describes what happens
whenever a user has a single queued correction and a colleague, or their own
other device, syncs anything in the meantime. A client author who treats this
as an edge case will deprioritize implementing it and will be wrong about how
often it fires.

**This rule governs PULL only. A `conflict` or `rejected` PUSH RESULT is the
opposite: the client MUST adopt the server's authoritative row, not preserve
its own.** The two paths look similar - both involve a row this device has
edited that the server disagrees with - but they are not the same decision:
on pull, the server hasn't yet seen this device's queued mutation, so keeping
the local edit on screen is honest. On a `conflict`/`rejected` push result, the
server has just adjudicated that very mutation and lost (or been refused
outright); preserving the local edit here would leave a rejected change on
screen as though it had succeeded, which is worse than either accepting or
losing honestly. "The row has a pending mutation" is **not** sufficient on its
own to decide which behavior applies - both paths can be true of the same row
at the same moment - so an implementation needs a signal for which code path
it is on, not just whether a mutation is queued. TimelyKit's push-result
handler adopts the server row unconditionally for `applied`, `conflict`, and
`rejected` alike (only pull sets its equivalent of "preserve unpushed edits" at
all), then parks the `conflict`/`rejected` disagreement for the user to see.
Both TimelyKit and Android converged on this; TimelyKit's first draft had the
two paths inverted and only an existing local-store test caught it - this is
exactly the kind of distinction that is cheap to state once here and expensive
for three clients to each rediscover on their own.

### 7.2 Push queue semantics

- **Ordered.** FIFO per device. One in-flight batch at a time. A device MUST NOT
  push two batches concurrently; a later mutation must never overtake an earlier
  one for the same row.
- **Durable.** The queue is persisted and survives app termination, force-quit,
  and OS restart. It is not held in memory.
- **At-least-once.** Delivery is retried until a terminal result arrives.
  Duplicate delivery is expected and is absorbed by `mutation_id`.
- **Batch-capped.** At most 200 mutations or 1 MiB serialized per batch,
  whichever binds first. At most 50 when `atomic: true`.
- **Terminal statuses.** `applied`, `conflict`, and `rejected` all dequeue.
  Only transport errors, 5xx, and 429 are retried, with full-jitter exponential
  backoff (base 2s, cap 5m). A mutation absent from `results` was not processed
  and stays queued.
- **Pull after push.** A successful push MUST be followed by a pull. The server
  produces side effects on rows the pusher did not touch - auto-vivified
  projects, duplicate flags raised on *other* spans - and `next_cursor` in the
  push response is only a hint.
- **Coalescing.** A client MAY coalesce consecutive updates to the same row while
  they are still queued, keeping the newest payload and the newest `mutation_id`.
  It MUST NOT coalesce across a delete, and MUST NOT coalesce anything already
  in flight.

### 7.3 Split and merge

Split and merge are not distinct operations. They are ordinary create/update/
delete mutations submitted in one `atomic: true` batch, with lineage recorded in
`derived_from_span_ids`:

- **Split** one span into N: N creates (each citing the original in
  `derived_from_span_ids`) plus one delete of the original.
- **Merge** N spans into one: one create citing all N, plus N deletes.
- **Reassign / retitle / rebill**: a plain `update`. No atomicity needed.

Expressing them this way means the conflict rules need no special cases, the
lineage survives, and a companion that goes offline mid-edit either lands the
whole correction or none of it.

## 8. Conflict Resolution

### 8.1 Default rule

Per-entity **last-write-wins** on `updated_at_effective`. On an exact tie, the
**lexically greater `origin_device_id` wins**. The tie-break is a value both
sides already have, so every client that sees the same two versions computes the
same winner without asking the server - which matters because a client may
resolve locally before it ever gets to push.

**The tie-break is computed on the *stored* `origin_device_id`, never on the raw
pushed payload, and that is precisely what makes it client-independent.** The
server derives the value once - `payload["origin_device_id"] || <pushing
device>` - and uses that one value both to store the row and to adjudicate the
tie. `origin_device_id` is therefore **safely omittable**; an omitted field and
an explicit `null` behave identically.

The reason it must be the stored value is the guarantee in the paragraph above.
What a client can see of another device's write is the `origin_device_id` it
pulled - never that device's request body. If the server adjudicated on the raw
payload, it would be comparing something no client can observe: a client that
omitted the field would be compared as `""` and lose every exact tie, so two
clients with different serialization habits would compute *different* winners
from the same two versions. That is the exact determinism this rule exists to
provide, so adjudicating on anything other than the stored value contradicts it.

What this rule does **not** claim is that `origin_device_id` is unforgeable.
Device identity is client-asserted throughout this protocol - the bearer token
identifies a user and a session, never a device, and both `MutationRequest.device_id`
and the per-mutation `origin_device_id` are supplied by the client, so ignoring
the payload would move the assertion rather than remove it. The value must be a
well-formed UUID - an arbitrary high-sorting string is rejected
`validation_failed` - but because genuine ids are UUIDv7 and therefore
timestamp-led, an all-`f` UUID outranks every real one. A client that stamps one
will win ties it would otherwise lose.
That is accepted, and it is not a tenancy hole: workspace isolation is enforced
separately, so the only rows affected are the client's own, in its own workspace,
against its own other devices. **Convergence is unconditional; attribution is
asserted.** Every client, honest or not, still computes the same winner from the
same two stored versions, which is the property clients depend on.

`base_revision` is advisory for ordinary LWW: a stale base still applies, but the
result is marked `stale_base: true` and the client should pull. It becomes
decisive only for the closed-span guard and locked days.

### 8.2 Conflict matrix

| # | Entity | Situation | Resolution |
|---|--------|-----------|------------|
| 1 | any | update vs update | LWW on `updated_at_effective`; tie -> greater `origin_device_id`. Result `applied`, loser silently overwritten. |
| 2 | any | update vs delete | **Delete always wins.** Tombstone is absorbing, regardless of timestamps. Result for the losing update: `conflict` / `tombstoned`, with the tombstone returned. |
| 3 | any | delete vs delete | Idempotent. Earliest `deleted_at` retained. `applied`. |
| 4 | any | create with an existing id | Degrades to update under rule 1. Client-generated ids make this safe. |
| 5 | any | `updated_at` far in the future | Clamped to receipt time (4.1), then rule 1. `low_confidence` flag raised. |
| 6 | `time_span` | stale update sets `end: null` on a closed span | **`rejected` / `span_reopen_forbidden`.** A closed span is evidence; a device that has not seen the close must not undo it. |
| 7 | `time_span` | fresh update sets `end: null` (`base_revision` == current) | `applied`. A user deliberately reopening a span they can currently see is legitimate. |
| 7a | `time_span` | update **omits** `end` entirely | Not a reopen. A partial update that does not touch the field never triggers rows 6 or 7 - see the note below. |
| 8 | `time_span` | two spans overlap in time | **Not a conflict.** Parallel work is the product. Nothing is merged, trimmed, or rejected. |
| 9 | `time_span` | overlap between two *billable* spans resolving to *different* clients | `applied`, and the server raises `billing_overlap` on **both** rows. Double-billing risk is a review item, not an error. |
| 10 | `time_span` | suspected duplicate (see 8.3) | `applied`, and the server raises `suspected_duplicate` on **both** rows, each citing the other in `related_id`. Never auto-merged. |
| 11 | `time_span` | update to a span with `locked_at` set, or starting on/before `workspace_policy.locked_through` | `rejected` / `locked_day`, unless the mutation also clears the lock and the actor may reopen (US-068), which raises `reopened_after_approval`. |
| 12 | `client`/`project`/`ticket` | create whose `canonical_name` maps to a different id | `conflict` / `duplicate_name`. Client performs a reference rewrite (6.2). |
| 13 | `client`/`project`/`ticket` | rename to a `canonical_name` already taken | `conflict` / `duplicate_name`. The user is offered a merge (6.3). |
| 14 | `vision_analysis` | any `update` | `rejected` / `immutable_entity`. Append-only; re-analysis creates a new row. |
| 15 | `censored_screenshot` | any `update` | `rejected` / `immutable_entity`. |
| 16 | `censored_screenshot` | `create` | `applied`, with a cascade: the referenced `screenshot` is tombstoned, its `vision_analysis` rows are tombstoned, any stored blob is deleted and `upload_state` set to `purged`. Returned as `side_effects`. |
| 17 | `screenshot` | client tries to set `upload_state` / `blob_*` | Fields ignored. Server owns them. |
| 18 | `device` | mutation from a device other than the subject, **via `/sync/mutations`** | `rejected` / `not_device_owner`. See the note below - this rule applies on the mutation path only. |
| 19 | `workspace_policy` | mutation from a non-admin | `rejected` / `permission_denied`. |
| 20 | `user_settings` | update vs update | Rule 1 on the whole document. Device-local fields are not in the document, so they cannot conflict. |
| 21 | any | `workspace_id` in payload differs from the request | `rejected` / `workspace_mismatch`. |
| 22 | any (atomic batch) | any member not `applied` | Whole batch rolled back, `409`, every result `rejected` / `batch_rolled_back`. |

**Note on rows 6, 7 and 7a - `"end": null` is not the same as an absent `end`.**

The server distinguishes *present-and-null* from *absent*, and the two are
different instructions. JSON Schema cannot express the difference, so it is
stated here and it is binding:

- **`"end": null` present** asserts that the span is open. Against a row the
  server holds closed, that is a deliberate reopen - row 7 when `base_revision`
  is current, row 6 (rejected) when it is not.
- **`end` absent** is a partial update that leaves the field alone. It can never
  reopen anything, whatever `base_revision` says.

The guard fires on the **server's** copy, not on the payload alone: it applies
only when the stored row is already closed. So a client that sends whole
documents - all of ours do - and includes `"end": null` for a span it believes
open is behaving correctly. An ordinary edit to a genuinely open span is never
mistaken for a reopen, because the stored row is open too and the guard does not
engage.

**`locked_at` behaves identically**, and the consequence is worse. Row 11's
escape hatch tests `Map.has_key?(payload, "locked_at") and payload["locked_at"]
== nil` - so a present-and-null `locked_at` is the *instruction* to clear an
approval lock, which an admin is permitted to do. A client that always
serializes the field therefore asks to unlock an approved day on every edit, and
succeeds the moment its copy is stale. Same rule, same fix.

**The client requirement**, for both fields:

| Situation | Send |
|-----------|------|
| The field has a value | the value |
| The user genuinely emptied it (reopen, or clear the lock) | explicit `null` |
| Anything else | **omit the key** |

Deriving the middle row needs the *prior* state, not just the new one - "the
user reopened this" and "this was already open" produce identical entities and
are distinguishable only by what the row looked like before the edit.

Two failure modes, in opposite directions:

- **Always serializing** asserts a reopen and a lock-clear on every edit. It
  looks correct in testing, because the guards also require the *server's* copy
  to be closed or locked; the bug only appears once another device closes a span
  or locks a day and this client has not pulled it yet.
- **Omitting nulls globally** - `encodeIfPresent` in Swift, `explicitNulls =
  false` in Kotlin, `omitempty` in Go - makes a genuine reopen or lock-clear
  inexpressible, because the key vanishes at exactly the moment it carries
  meaning. It also drops `deleted_at`, `ticket_id` and `origin_device_id`, which
  are nullable **and** required, producing bodies that fail this contract's own
  schema.

The correct shape is one deliberate conditional in the payload builder, covering
`end` and `locked_at` and commented so nobody widens it into a blanket
"omit nils" serializer setting - that failure mode is covered above. **This is
not, however, the complete list of presence-sensitive fields on this entity**;
see the general rule and the site table immediately below, which supersedes any
reading of "two fields" as closed.

**Presence-sensitivity is the general rule, not a list of exceptions.**

An earlier revision of this note claimed the presence-sensitive set was "exactly
three keys". That was wrong, and the reason is worth recording because it is the
same shape as the bugs above: the audit grepped for `Map.has_key?(payload, ...)`
and so missed every site testing presence on a map *derived* from the payload.
A narrow method returned a confident answer.

Every site in the server's sync domain that distinguishes absent from present:

| Site | Governs | Absent means |
|------|---------|--------------|
| `Entities.payload_to_attrs/2` | `start`, `end` on `time_span` | column untouched |
| `Mutations.guard_reopen/3` | `end` — the row 6/7 reopen guard | not a reopen |
| `Mutations.guard_locked/3`, and the `reopened_after_approval` flag | `locked_at` | not a lock-clear |
| `Resolver.mentions?/2` | the client / project / ticket **reference group** on `time_span`, `project`, `ticket` | reference untouched |
| `Devices.merge_param/3` | fields on `PATCH /devices/{id}` | field untouched |

The two rows that read `attrs` rather than `payload` are the ones the narrow
grep missed, and `Resolver.mentions?/2` is the more instructive of them. It
exists because §6.1 step 5 — "*_id absent and *_name empty means the reference
is genuinely null" — is about a client that **has** no reference, not a payload
that never **mentions** one. Conflating those made an ordinary title edit
silently unassign a span's client and project, dropping the row out of every
billing rollup for that client. That is worse than the reopen case, because a
reopen is visible and an unassignment is not.

So the rule for clients is the simple one, and it holds everywhere:

> **Absence means "I am not speaking about this."** Send a field only when you
> have information about it. A value — including `null` — is a claim.

Two consequences worth stating:

- A field becoming presence-sensitive is **not** a breaking change under this
  rule, because a client that only speaks when it knows was already correct.
  It *is* breaking for a client that always serializes everything, which is
  precisely why that habit is the thing to avoid rather than a thing to manage.
- **An explicitly empty name still clears a reference.** "Unassign this" stays
  expressible; it is the *unmentioned* case that is now silent.

**A related hazard that is *not* presence-sensitive.** `merged_into_id` on
`client`, `project` and `ticket` is plain `@castable` with no presence check, so
a null simply sets the column - and `Sync.Resolver` follows that pointer to
redirect references. A client that has not yet pulled a merge and always
serializes the field will **un-merge** the row on its next ordinary edit. The
rule for clients is broader than presence-sensitivity, then: *do not send a
value for a field the server manages and you have no information about.*
Omission is how a client says "I don't know", and a null is a claim.

**Note on row 18 - `not_device_owner` is path-dependent.**

As originally written, row 18 was unenforceable on `PATCH /devices/{device_id}`,
and this table claimed otherwise. That request carries **no device identity of
its own**: the path names the device being *edited*, the bearer token names a
*user*, and nothing in it says which device is doing the asking. There is no
value to compare, so "a mutation from a device other than the subject" has
nothing to test against.

What each path actually enforces:

| Path | Identity available | Enforced |
|------|--------------------|----------|
| `POST /sync/mutations` | `device_id` in the request body | **Row 18 as stated.** A `device` mutation whose payload id differs from the pushing `device_id` is `rejected` / `not_device_owner`. |
| `PATCH /devices/{device_id}` | bearer token only | **User ownership.** The caller must own the device named in the path; otherwise `rejected` / `not_device_owner`. A user may rename any of *their own* devices from any of them, which is the behaviour a settings screen needs. |

This is a deliberate difference, not an oversight in the implementation - the
same reason code covers both because the user-facing meaning is the same ("that
device isn't yours"), but the check is genuinely different. A client MUST NOT
assume that being able to `PATCH` a device implies it could mutate that device
through `/sync/mutations`.

### 8.3 Suspected duplicate detection

Duplicates arise honestly: the same workday pushed from a restored backup, a
replay past the 30-day mutation window, or a user recreating a span on a phone
that had not yet pulled.

On every `time_span` create or update the server scans live spans in the same
workspace. A pair is a **suspected duplicate** when all hold:

- different `id`;
- `|start_a - start_b| <= 120s`;
- both `end` null, or `|end_a - end_b| <= 120s`;
- same resolved `project_id`, or both null;
- `canon(title_a) == canon(title_b)`, or either title is empty.

A pair is a **billing overlap** when all hold:

- temporal intersection > 60s;
- both `is_billable`;
- resolved `client_id`s differ (including one being null).

**What the server does:** appends a `ReviewReason` to `review_reasons` on both
rows with `raised_by: server` and `resolution: pending`, sets
`review_state: needs_review`, and bumps `server_revision` on both so the flag
propagates to every device.

**What the server does not do:** merge, delete, adjust boundaries, pick a
winner, or hide either row. "Review beats recall" is a UX principle from the
product brief - the user has context the server does not, and an auto-merge that
guesses wrong destroys billable evidence. The flag is cleared only by a client
mutation setting `resolution` to `accepted`, `dismissed`, or `merged`.

Detection is bounded: the scan is limited to spans whose `start` is within 24
hours of the candidate. A workspace with a pathological number of same-titled
spans in one window caps flag generation at 20 pairs per mutation.

## 9. Idempotency and Replay

Phase 5 of the ROADMAP requires duplicate event suppression. Two independent
mechanisms provide it.

### 9.1 The mutation log

Every mutation carries a client-generated `mutation_id` (UUIDv7, globally
unique). The server persists, for each applied mutation:

`(workspace_id, mutation_id, device_id, status, reason, entity_kind, entity_id, resulting_server_revision, applied_at)`

Retention is **at least 30 days**; 45 is recommended so that a device offline
for a month still lands inside the window.

On receiving a `mutation_id` already in the log, the server returns the
**original recorded result** with `replayed: true`. It does not re-apply, does
not bump `server_revision`, and does not re-run duplicate detection. Uniqueness
is enforced by a unique index on `(workspace_id, mutation_id)`, so two
concurrent deliveries of the same batch cannot both apply - the loser's insert
fails and is answered from the log.

### 9.2 Client-generated ids as the backstop

Past the retention window the log no longer protects a replay. Client-generated
ids do: a replayed `create` for an id that already exists degrades to an update
under rule 4, converging on the same row rather than producing a second one.
This is why locally minted primary keys are a correctness property and not just
an offline convenience.

The one case neither mechanism covers is a user genuinely re-entering the same
work by hand on a device that had not pulled. That produces two rows with
different ids, which is what 8.3 exists to catch.

## 10. Privacy and Screenshot Gating

### 10.1 The invariant

Screenshot **image bytes** default to never leaving the device. Screenshot
**metadata** always syncs.

Byte upload requires **both** gates open:

1. `workspace_policy.screenshot_upload_allowed == true` (default `false`)
2. the origin device's `local_only_screenshots == false` (default `true`)

Both default to the privacy-preserving value, and the effective gate is a
logical AND, so a device can only tighten and never loosen. `POST
/api/v1/screenshots/{id}/blob` returns `409 blob_upload_forbidden` with a
`gates` object naming which side is closed. The server does not buffer or retain
a rejected body.

Flipping the workspace flag back to `false` moves existing blobs to
`purge_pending` and then `purged`. Metadata rows survive; the timeline does not
develop holes.

### 10.2 A byte-free client is a complete client

Every read surface is metadata-sufficient. For a local-only screenshot a
companion renders:

- `captured_at`, `active_app_name`, and the owning span;
- `origin_device_id` resolved to a device name - "captured on Keith's MacBook Pro";
- `vision_analysis.status_update` and `.evidence` - the one-sentence description
  of visible progress and the phrase naming the visible clues.

That text is the recall surface, and it is why the vision analysis is a
first-class synced entity rather than a macOS-local nicety. `GET .../blob`
returning `404 blob_not_available` is the **normal** path; clients MUST treat it
as unremarkable and MUST NOT surface it as an error.

### 10.3 `raw_response` is image-equivalent

`VisionAnalysisRecord.rawResponse` is the model's verbatim output describing the
screen. If image bytes stay on device but a full textual transcription of those
same pixels syncs freely, the privacy promise is hollow.

`raw_response` is therefore gated by the same double gate, controlled by
`workspace_policy.sync_vision_raw_response` (default `false`). When withheld the
field is `null` and `raw_response_withheld` is `true`, distinguishing "policy
suppressed this" from "the source never had it".

`status_update`, `evidence`, `inferred_project`, and `inferred_task` are bounded
summaries authored under a prompt that constrains them to progress descriptions,
and they always sync. This is a deliberate line, not an oversight: the product
does not work without them.

### 10.4 Censorship as a tombstone cascade

The macOS agent, on a privacy-sensitive vision result, deletes the PNG, removes
the `ScreenshotRecord` from its array outright, drops the analysis, and appends a
`CensoredScreenshotRecord`. That local hard-delete cannot be expressed as-is in a
protocol that never hard-deletes.

The mapping: the client pushes a `censored_screenshot` **create**. The server
treats it as an assertion of censorship and cascades - tombstones the
`screenshot`, tombstones its `vision_analysis` rows, deletes any stored blob,
sets `upload_state: purged` - returning all of it in `side_effects`. Other
devices receive tombstones plus the censorship record through the ordinary pull
and converge on the same state.

`deleted_local_file` is the origin device's report about its own disk. It says
nothing about any other device and MUST NOT be rendered as a workspace-wide
claim.

### 10.5 Secrets that never sync

`VisionLLMSettings.apiKey` is absent from this contract entirely. It lives in the
device keychain. The macOS model's `env:` indirection is a device-local
convenience and is not a wire concept.

## 11. Authentication and Offline Behavior

### 11.1 Endpoints

Timely does not define auth. It uses the scaffold's existing routes:

| Route | Purpose |
|-------|---------|
| `POST /api/v1/auth/register` | Create an account. |
| `POST /api/v1/auth/login` | Exchange credentials for tokens. |
| `POST /api/v1/auth/refresh` | Exchange a refresh token for a new access token. |
| `GET /api/v1/auth/me` | Current principal. |

Access token: 1 hour. Refresh token: 7 days. Presented as
`Authorization: Bearer <access_token>`.

### 11.2 Refresh on 401

1. Any Timely endpoint returning `401` with `code: token_expired`:
   call `POST /api/v1/auth/refresh` **once**, then retry the original request
   **once**.
2. Refresh succeeds: store the new access token, and the new refresh token if one
   was issued, **before** discarding the old one. If the server rotates refresh
   tokens it MUST honor the previous token for 60 seconds after rotation, so a
   client that crashes mid-write is not locked out.
3. Refresh fails with `401`: mark the session `reauth_required`. Do **not** clear
   the local store. Do **not** clear the push queue.
4. Concurrent 401s: a client MUST serialize refresh - one in-flight refresh, with
   other requests waiting on it - or a burst of parallel syncs will race and
   invalidate each other's rotated tokens.

### 11.3 Offline grace

**An expired token MUST NOT degrade the app.** With no network, an expired access
token, or an expired refresh token:

- All reads are served from the local store. The local store is the UI's source
  of truth at all times, online or not; the network is a background reconciler.
- All writes are accepted and appended to the push queue. Nothing is gated on
  token validity, network reachability, or server acknowledgement.
- The queue grows without bound and without expiry. Queued mutations are never
  dropped for age. (`updated_at` clamping in 4.1 handles the resulting
  timestamp staleness.)
- The UI surfaces sync state honestly - "12 changes waiting to sync",
  "sign in to sync" - as status, never as a blocking modal.

### 11.4 Reauthentication and queue safety

On reauth:

- **Same `user_id`** as the queue was built under: flush normally.
- **Different `user_id`**: the client MUST NOT flush. Quarantine the queue,
  keep it against the previous identity, and prompt. Silently pushing one
  person's captured workday into another person's workspace on a shared device
  is the worst failure this protocol can produce, and it is entirely preventable
  here.

`device_id` survives reauth and reinstall where possible;
`POST /api/v1/devices` is idempotent by client-supplied `device_id`.

## 12. Worked Example

Two devices, one span. Device A is the macOS agent
(`019318a0-7f3c-...-2f6a1c3d5e70`), device B an Android companion
(`019318a0-8b12-...-11c9de4477aa`). Note that B's id sorts lexically **greater**
than A's - it wins ties.

### T0 - Device A, offline

Keith works on a laptop with no network. The agent starts a timer span at 09:02
and stops it at 10:47:30. It mints a UUIDv7 for the span. Following the macOS
model, the span references its project by name only.

Locally the agent also upserts "Acme" and "Acme / Redesign", computing
deterministic v5 ids per 3.2. Three mutations enter the queue. Two screenshots
are captured; their metadata rows queue too. Their PNGs stay on disk -
`local_only_screenshots` is `true`.

### T1 - Device A comes online and pushes

```
POST /api/v1/sync/mutations
{ "workspace_id": "0192f7a1-…", "device_id": "019318a0-7f3c-…", "atomic": false,
  "mutations": [ …client…, …project…,
    { "mutation_id": "019318c0-0001-…", "entity": "time_span", "op": "create",
      "base_revision": null,
      "payload": { "id": "019318b4-1a2b-…", "title": "Timeline canvas keyboard pass",
                   "client_name": "Acme", "project_name": "Redesign",
                   "start": "2026-07-27T09:02:00Z", "end": "2026-07-27T10:47:30Z",
                   "source": "timer", "is_billable": true,
                   "updated_at": "2026-07-27T10:47:30Z",
                   "origin_device_id": "019318a0-7f3c-…" } } ] }
```

The client and project creates land first and are `applied` at revisions 1901
and 1902. The span create resolves `project_name: "Redesign"` by canonical name -
a hit, because the project arrived moments earlier in the same batch - and is
`applied` at revision 1903 with `project_id` filled in. Had the client/project
mutations been missing entirely, step 4 of 6.1 would have vivified them and
returned them as `side_effects`.

Device A pulls, advances its watermark to 1903, and dequeues.

### T2 - Device B pulls and edits

Keith opens Android on the train. B pulls from its watermark, receives the span
at revision 1903, and stores it. Reviewing the day he notices the last 50 minutes
were a client call, not the redesign. He retitles the span and marks it
non-billable. B has no network, so the update queues:

```
{ "mutation_id": "019318c0-0031-…", "entity": "time_span", "op": "update",
  "base_revision": 1903,
  "payload": { "id": "019318b4-1a2b-…", "title": "Redesign build + client call",
               "is_billable": false, "end": "2026-07-27T10:47:30Z",
               "updated_at": "2026-07-27T18:30:00Z",
               "origin_device_id": "019318a0-8b12-…" } } 
```

### T3 - Device A edits the same span concurrently

At 18:31 wall-clock on A, Keith adds a note to the same span from the Mac. A is
online, so it pushes immediately with `base_revision: 1903` and
`updated_at: 2026-07-27T18:31:00Z`. Applied at revision 1908. `stale_base` is
false; nothing has conflicted yet.

### T4 - Device B reaches network and pushes

B's mutation has `updated_at_effective` = min(18:30, receipt at 19:05) = **18:30**.
The server's row has `updated_at_effective` = **18:31**, set by A.

Rule 1 applies: A's 18:31 is later, so **A wins the whole row**. B's edit is
overwritten. B's result:

```
{ "mutation_id": "019318c0-0031-…", "status": "applied", "stale_base": true,
  "entity": { …server's authoritative row, A's version, revision 1908… } }
```

The status is `applied` because the mutation was processed and the row was
evaluated; `stale_base: true` and the returned entity tell B that its local copy
is superseded. B adopts the returned row. Keith's retitle is gone, and B's UI
shows the span as A last left it.

**This is entity-level LWW behaving as specified, and it loses a real user
edit.** It is the accepted cost of a rule that three independent client
implementations can compute identically without vector clocks or CRDTs. The
mitigation is product-level: B raises a local "your edit was superseded" notice
with a one-tap reapply, which pushes a fresh update at current `updated_at`.
Section 13 records field-level merge as the intended fix.

Had both edits carried the same `updated_at_effective`, the tie-break would have
awarded the row to **B**, whose `origin_device_id` (`…8b12…`) sorts above A's
(`…7f3c…`) - and both devices would have computed that same answer locally.

### T5 - The duplicate that is not resolved

Keith, not seeing his correction land, recreates the call as a fresh span on B:
09:57 to 10:47:30, "Client call", same project, billable.

The server applies it - it is a legitimate create with a new UUIDv7 - and then
runs 8.3. Start times are 55 minutes apart, so it is not a suspected duplicate.
But it overlaps the original span by 50 minutes, both are billable... and both
resolve to the same client, so rule 9 does not fire either. No flag. Two
overlapping billable spans for one client is exactly the parallel-work case
Timely is built for, and the weighted rollup in `GET /api/v1/reports/summary`
already prevents that overlap from being billed twice: `elapsed_seconds` counts
both, `weighted_billable_seconds` splits the contested 50 minutes evenly.

Had the new span been billed to a *different* client, rule 9 would have fired,
flagging both rows `needs_review` and surfacing a `billing_overlap` warning in
the report - visible before export, as Phase 2 requires.

## 13. Known Limitations

Recorded so that no implementer has to rediscover them.

1. **Entity-level LWW loses concurrent edits to disjoint fields**, as T4
   demonstrates. Field-level merge (per-field `updated_at`, or a small
   last-writer-wins register per field) is the intended v2. It is deferred
   because three hand-written client implementations must agree exactly, and
   entity-level LWW is the version they can all get right first.

2. **RESOLVED - presence-sensitive fields are a client requirement, not a
   protocol gap.**

   An earlier draft of this document recorded a limitation here: that a client
   sending whole-document payloads cannot express row 7a's partial update, so an
   unrelated edit to a span closed on another device would be `rejected` /
   `span_reopen_forbidden` rather than merged - and that fixing it required a
   protocol-level field mask.

   **That was wrong, and the mistake is worth keeping visible.** The server does
   not treat a payload as a whole-document replace. `Timely.Sync.Entities`
   carries `end` into the update only when the client actually sent the key, and
   Ecto's `cast/3` ignores keys absent from the params - so an omitted field is
   genuinely left alone. Rows 6, 7 and 7a work exactly as specified. Nothing in
   the protocol needed changing.

   What is real is the **client requirement**, and it is easy to get wrong in a
   way that looks harmless:

   - Send `end` and `locked_at` only when they carry a value, or when the user
     genuinely emptied them.
   - A client that *always* serializes them asserts a reopen and a lock-clear on
     every edit. It appears to work, because the server's guards also require
     its own copy to be closed or locked - so the bug only surfaces once another
     device closes a span or locks a day and this client has not pulled it yet.
     Then an innocent title edit becomes a `span_reopen_forbidden` rejection
     that also loses the title, or - for an admin - a silently cleared approval
     lock.
   - The fix is one deliberate conditional in the payload builder, **not** a
     serializer setting. Turning on "omit nils" globally drops `deleted_at`,
     `ticket_id` and `origin_device_id` too, which are nullable **and required**,
     producing bodies that fail this contract's own schema. See the note under
     section 8.2 and the guidance in `timely-api.yaml` under `TimeSpan.end`.

   **How this was found is the argument for the whole approach.** Three
   independent implementations were built against one contract. Android omitted
   the key, Swift always sent it, and the disagreement between two clients that
   both passed their own tests is what exposed the real semantics - first that
   the limitation was fictional, then that `locked_at` had the same defect and
   a worse consequence. Neither client could have found it alone: each was
   self-consistent. The cost of writing `canon()` and the wire format three
   times buys exactly this.

3. **`canon()` must be implemented three times.** Any divergence between Elixir,
   Swift, and Kotlin silently produces duplicate taxonomy rows. Pinned by
   `apps/shared/contracts/canon-fixtures.json`; conformance is mandatory
   (section 14).

   One residual gap the fixture documents rather than solves: `canon()`
   lowercases rather than case-folds, so `Straße` and `strasse` are different
   clients. It is reachable by ordinary copy-paste from a word processor and is
   left to the user-facing duplicate merge (US-085) because fixing it means
   hand-maintaining a sharp-s mapping table in three languages, which is a
   larger divergence risk than the problem it solves. (An earlier draft of this
   document listed a second gap here - that NFKC does not map U+2019, so
   `Bob's` and `Bob’s` were different clients. Quote and apostrophe
   normalization (3.3, step 3) closed that gap; it is no longer a limitation.)

4. **The deterministic-id scheme is name-derived at mint time only.** After a
   rename, an offline device vivifying the new name mints a colliding id and
   takes the `duplicate_name` path (6.2). This is correct but requires clients to
   implement reference rewrite, which is the fiddliest client-side requirement in
   this document.

5. **`screenshot.file_name` is not unique.** The macOS agent formats it at second
   resolution (`timely-yyyyMMdd-HHmmss.png`), so two captures in one second
   collide. It is advisory provenance only; nothing may key on it.

6. **`deleted_local_file` is single-device truth** on a row that syncs to all
   devices. It is a report, not a workspace fact.

7. **Idle events, sleep boundaries, and resumption events have no entity here.**
   US-041 through US-050 currently derive them from gaps between spans. If they
   become first-class rows they need their own bucket and their own conflict
   rules; that is a contract revision, not an additive change.

8. **Approvals are a single `locked_at` field, not a workflow.** Phase 3's
   approval queue, roles, and audit log (US-067, US-068) will need their own
   entities. `review_state: approved | locked | disputed` is a placeholder
   sufficient for single-user Phase 1 and 2.

## 14. Conformance

**Fixture:** [`apps/shared/contracts/canon-fixtures.json`](../apps/shared/contracts/canon-fixtures.json)
- 68 `canon()` cases, 8 composite key cases (76 total).

### 14.1 Conformance is mandatory

**A platform MUST pass every case in the fixture before it is permitted to sync
against a shared workspace.** This is a gate, not a guideline. It applies to the
Elixir server, the Swift package, and the Kotlin app equally, and it applies
again after any change to `canon()`, to the strip set, to the whitespace set, or
to the key formats in 3.2.

The reason for the hard gate is the failure mode. A `canon()` divergence does not
throw, does not log, and does not fail a sync. Two implementations that disagree
on one code point simply mint two different UUIDs for one client, and from that
moment the workspace contains two "Acme" rows that accumulate time independently.
Nobody notices until an invoice is short. By then the damage is spread across
weeks of spans and the repair is manual.

Every other rule in this document announces its own violation - a rejected
mutation, a conflict result, a 410. This one does not. The fixture is the only
thing standing between three hand-written implementations and silent data
divergence, which is why it gets a gate of its own.

### 14.2 What to assert

For each entry in `canon_cases`:

1. `canon(input) == expected_output`
2. `uuid5(workspace_id, expected_client_key) == expected_client_id`

Compare against `expected_output_codepoints`, not only the string. A terminal, a
diff viewer, or an editor will happily render a combining mark or a zero-width
character as though it were not there, turning a real failure into a passing
test.

An `expected_client_id` of `null` means `canon()` produced the empty string. The
implementation MUST NOT mint an id and MUST NOT create an entity - the reference
is simply absent (6.1 step 5).

For each entry in `composite_cases`, assert the composed key string and the
resulting id for the project and ticket forms, including the empty-parent case
(`"project:/internal"`).

### 14.3 What the fixture covers

Unicode case folding and the Turkish dotted/dotless `i`; the Greek final sigma
divergence between Elixir and the JVM/Swift; NFC vs NFD convergence and the
deliberate non-folding of diacritics; NFKC compatibility mappings (ligatures,
fullwidth, superscripts, circled digits, Roman numerals, halfwidth katakana);
leading, trailing, and interior whitespace runs across the full `White_Space`
set including U+1680, which NFKC does not touch; zero-width and non-breaking
characters, including the ones that must be stripped and the two that must be
preserved; empty and whitespace-only input; quote and apostrophe convergence
(smart-quote variants collapsing onto their ASCII equivalents, including the
U+0149 ordering proof) alongside the punctuation and separators that are
deliberately left unfolded; digits in three scripts; emoji ZWJ sequences; CJK;
RTL Arabic and Hebrew; and long input.

### 14.4 Adding cases

Edit the generator, regenerate, and commit the generator and the JSON together.
Never hand-edit `expected_output` or any `expected_*_id` - they are computed, and
a hand-written expectation that happens to match a buggy implementation is worse
than no test.

Add a case whenever a `canon()` bug is found in **any** of the three
implementations, and add it **before** fixing the bug. A bug that reached
production is by definition not covered here yet.
