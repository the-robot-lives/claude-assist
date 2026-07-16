# Merge-Conflict Avoidance

Prevent conflicts at **plan time** instead of resolving them at merge time. A conflict is not an accident that happens during integration — it is a decision made (or skipped) during partitioning. This reference is the full playbook behind the SKILL summary: ownership maps, contested-path recipes, the shared-surface catalog, contract-freeze mechanics, workspace isolation, and integration order.

## 1. The Premise

Two agents editing one file is a merge conflict **scheduled in advance**. The only question is whether you pay for it now (cheap) or later (expensive).

| | Prevention (plan time) | Resolution (merge time) |
|---|---|---|
| Cost | ~1 min: assign the path to one track | ~1 hr: three-way-merge archaeology |
| Who | Coordinator, once, with full plan in view | Whoever's unlucky at the gate, with partial context |
| Risk | None — deterministic | Silent semantic breakage past a clean textual merge |

The asymmetry is **worse for agents than humans**. A human resolving a conflict carries tacit context — why the other change exists, which side is authoritative, what the file is "supposed" to become. Agents lack that; they see two hunks and a marker. Given the cost curve, the partitioning minute is never the wrong trade.

**Rule:** if a merge conflict is possible, the partition was incomplete. Fix the partition, not the merge.

## 2. The Ownership Map

The ownership map is a **total function**: every path the plan touches maps to exactly one destination. No path is unowned; no path has two owners.

```
owner(path) → { track-id | contract: | integration: }
```

- **`track-id`** (e.g. `T2`) — exactly one track may edit this path for its whole lifetime.
- **`contract:`** — a Phase-0 artifact. Frozen. Editable only via CONTRACT-RFC (§5), never inside a track.
- **`integration:`** — touched **only** inside a gate, by whoever owns that gate. Never edited in a track.

### Glob conventions

Assign by glob, most-specific-wins, so new files fall into an owner automatically:

```yaml
# ownership map (lives in the work plan, not in chat)
"src/api/contract/**":        contract:      # frozen surface
"src/components/**":          T1             # frontend
"src/server/**":              T2             # backend
"cypress/e2e/**":             T3             # e2e tests
"test/unit/**":               T4             # backend tests
"test/fixtures/**":           T5             # fixtures
"src/server/routes.ts":       contract:      # override: route table is a contract
"src/index.ts":               integration:   # barrel — regenerated at gate
"**":                         UNASSIGNED     # sentinel — any hit here BLOCKS the plan
```

The map is the single source of truth and lives **in the work plan**, not in room chat. Chat records decisions about the map; it never *is* the map.

**Enforcement is a hard stop, not a courtesy.** An agent asked to edit a path outside its set must refuse — post `BLOCKED: path <p> owned by <owner>, requesting reassignment` and wait. A quiet edit "just this once" is the exact failure the map exists to prevent. The `UNASSIGNED` sentinel guarantees a discovered-mid-flight path surfaces as a block (§8) rather than a silent land-grab.

## 3. Contested-Path Resolution Recipes

When two tracks both need a path, pick the **highest** applicable recipe (they degrade in desirability top-to-bottom):

| Recipe | Use when | Result | Cost |
|--------|----------|--------|------|
| **Split the file** | The two tracks need *different* pieces of it | Each piece becomes a single-owner file | Low |
| **Extract an interface** | Both need the same *surface* but not the impl | Surface → `contract:`, impls stay per-track | Low |
| **Promote to contract** | It's config / schema / types / route table | Moves to Phase 0, frozen for all | Low–med |
| **Serialize** | Genuinely inseparable; edits truly sequential | One unit blocks the other; record why | High (kills parallelism) |
| **Duplicate-then-reconcile** | Trivially mergeable data file only | Per-track copies, reconciled at a gate | Med (risky if misapplied) |

### Split the file
The most common and best outcome. `utils.ts` that T1 and T2 both grew into → `utils/format.ts` (T1) + `utils/validate.ts` (T2). Extract the shared piece each track actually needs into its own owned file. If nothing is genuinely shared, the "contest" was just a fat file.

### Extract an interface
The contested surface becomes a **C-contract** both tracks key to, while implementations diverge into owned files. T1 and T2 both touched `PaymentGateway` → `contract: PaymentGateway` interface (frozen); `StripeGateway` (T2 impl) and the T1 mock both implement it independently. Neither edits the other.

### Promote to contract
If the contested file is *structurally* a contract — a type module, a JSON schema, an API route table, a shared enum — it was mis-classified. Move it to Phase 0 and freeze it. Contested config almost always belongs here.

### Serialize (last resort)
Make unit B block unit A so only one track edits the path at a time. This **converts parallel work back to serial** — the exact thing the skill exists to avoid — so it is the last resort and the plan must record *why* no split/extract/promote was possible. Revisit at retro.

### Duplicate-then-reconcile
Only for files that merge **trivially and mechanically** — append-only logs, disjoint key sets in a data file. Each track writes its own copy; a gate reconciles. Never use for code, ordered files, or anything with cross-line semantics; a clean textual merge there hides broken meaning.

## 4. Shared-Surface Catalog

The usual conflict magnets and their standing strategy:

| Surface | Strategy | Why |
|---------|----------|-----|
| Type / interface files | → `contract:` (Phase 0) | Every track keys to types; frozen once, consumed by all |
| API route tables | → `contract:` | The route list *is* the frontend↔backend contract |
| Barrel / index files (`index.ts`, `mod.rs`) | → `integration:`, **regenerate** at gate | Pure re-export aggregation; hand-merges thrash constantly |
| Lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`) | Single owner **or** `integration:` only | **Never** two tracks adding deps — the canonical unresolvable conflict |
| Generated code (protobuf, OpenAPI clients, ORM types) | **Regenerate** at gate, never hand-edit in a track | Source of truth is the generator input, not the output |
| Translations / locale files | Append-only protocol **or** per-track namespace files merged at gate | Shared flat maps collide on every key insert |
| Migrations | Sequence numbers assigned by coordinator at **plan time** | Two tracks grabbing `0007_` is a guaranteed collision |
| Shared test fixtures | Fixtures track (e.g. T5) owns them exclusively | One authority for seed/mock data keeps tracks consistent |

**Dependency changes are special.** Adding a dependency touches a lockfile, and lockfiles do not three-way-merge. Either route every `add-dependency` need through the single lockfile owner, or batch them at an integration gate. A track that adds a dep on its own has scheduled a merge conflict with every other track that did the same.

**Generated files are never hand-edited in a track.** The moment a track edits generated output, the generator's next run at the gate silently reverts it. Edit the input (schema, proto, spec — which is `contract:`), regenerate at the gate.

## 5. Contract Freeze Mechanics

A freeze is what lets a `contract:` path be *read by everyone and written by no one*.

**To freeze:**
1. Stamp a version in the plan: `contract: C1 @ frozen v1 — 2026-07-16 (sha abc123)`.
2. Announce it in the coordination room with a `STATUS`: `STATUS C1 — frozen v1 (sha abc123); tracks pin to this`.
3. Every track **pins** to the version it built against and does not chase edits.

**To change a frozen contract — CONTRACT-RFC only:**

```
CONTRACT-RFC C1 — add `currency` field to POST /orders — impact: T1, T3, T5
  reason:   backend needs multi-currency (v1 → v2)
  affects:  T1 (form), T3 (e2e assertions), T5 (fixtures)
```

The coordinator — not the requesting track — does the impact analysis:
1. Enumerate every track consuming the contract.
2. Accept or **reject** (a change touching 4 tracks may cost more than the feature).
3. If accepted: broadcast the ruling with a `STATUS` — `STATUS C1 — RFC accepted, v1 → v2; re-pin: T1, T3, T5` — stamp the new version, and list who must re-pin.

Tracks stay on the version they built against until they re-pin at their next gate. **No track edits a `contract:` path directly** — not even the one that requested the RFC. The coordinator (or a delegate it names) applies the change to the frozen artifact; that is what keeps "frozen" true.

## 6. Workspace Isolation

Ownership discipline prevents *logical* collisions; workspace choice decides how tracks physically share (or don't) a working tree.

| Option | Isolation | Use when | Integration implication |
|--------|-----------|----------|-------------------------|
| **Shared tree + ownership discipline** | Logical only | Tracks truly disjoint, small fleet, one machine | No merge — all edits already in one tree; gates just verify |
| **git worktrees per track** | Separate working dirs, shared `.git` | Standard (non-subtree) repo, one host | Merge/rebase branches in gate order |
| **Subtree-monorepo pattern** (below) | Full, per project subtree | This monorepo — subtrees, worktrees discouraged repo-wide | Reconcile copies back into the subtree at the gate |
| **Remote / cloud isolated runners** | Full, per-machine | Untrusted code, heavy resource isolation, cross-provider fleet | Merge via PRs / patch exchange |

**Selection:** smallest isolation that makes collisions impossible. A disjoint 3-track plan on one box needs only ownership discipline — worktrees add ceremony for no gain. Reach for stronger isolation when tracks share tooling state, when the harness can't be trusted to honor ownership, or when runners are on different machines/providers.

### The subtree-monorepo pattern

This repo manages `projects/` as **git subtrees, not submodules**, so a repo-root `git worktree` is discouraged (per CLAUDE.md). Two sanctioned variants isolate a single project subdir:

**Variant A — git-init in place:**
```bash
cd projects/<target>
git init && git add -A && git commit -m "base"   # temp repo, this subdir only
git worktree add ../.wt/<target>-T1 -b track/T1
git worktree add ../.wt/<target>-T2 -b track/T2
# ... tracks work in their worktrees ...
# CLEANUP (mandatory — do not leave nested .git behind):
git worktree remove ../.wt/<target>-T1
git worktree remove ../.wt/<target>-T2
rm -rf projects/<target>/.git ../.wt        # remove the temp repo + worktree root
```

**Variant B — staging copy:** copy the project into `Noizu/staging/`, then `git init` / worktree / cleanup there — leaves the live tree untouched entirely.
```bash
cp -r projects/<target> staging/<target>
cd staging/<target> && git init && git add -A && git commit -m "base"
# ... worktrees, work, reconcile ...
rm -rf staging/<target>                      # cleanup: remove the whole staging copy
```

**Cleanup is mandatory in both.** A leftover nested `.git` inside a subtree corrupts subtree push/pull and pollutes `git status` at the root. Treat cleanup as part of the gate, not an afterthought.

## 7. Integration Order

Gates land **pairwise, with one moving side.** Rebase the completing track onto the already-integrated base; never merge two independently-moved branches into each other (no criss-cross). One moving side means every conflict has an unambiguous "onto what."

```
base ──┬── T2 (backend)   ─┐
       │                   ├─G1─▶ base+T2 ──┬── T1 (frontend) ─┐
       └── contract froze  ─┘               │                  ├─G4─▶ integrated
                                            └── T3, T4 rebase ──┘
```

Order gates so each depends only on already-integrated work (the plan's gate list, e.g. front↔back before full integration).

**Conflict-at-gate playbook** (a conflict here means the ownership map had a gap):
1. **The gate owner resolves** — single authority, full context of both sides.
2. **Amend the ownership map** so the contested path now has one owner — the fix must make recurrence *impossible*, not just clear this instance.
3. **Re-pin** any track that consumed a bumped contract.
4. **Release ownership**: once a track is integrated and its gate passes, its exclusive paths are free to fold into `integration:` scope for later gates.

## 8. Anti-Patterns

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| "We'll sort it out at merge" | Defers a 1-min fix into an hour of archaeology, minus the context to resolve it | Partition at plan time (§2) |
| Two tracks "coordinating" edits to one file via chat | Chat is not a lock; interleaved edits still conflict, now with a false sense of safety | Split / extract / promote (§3) |
| Hand-editing generated files in a track | Next generator run at the gate silently reverts it | Edit the `contract:` input, regenerate at gate |
| Two tracks each `npm install` a dep | Lockfiles don't three-way-merge — guaranteed collision | Single lockfile owner or `integration:`-only (§4) |
| Unowned path discovered mid-flight | The map wasn't total; first writer silently wins | **STOP**, `BLOCKED` it, amend the map, *then* proceed |
| Grabbing the next free migration number ad hoc | Two tracks pick the same `NNNN_` | Coordinator assigns sequence numbers at plan time |

The through-line: **every collision traces back to a path that had zero owners or two.** Keep `owner(path)` total and single-valued and the merge phase becomes verification, not archaeology.
