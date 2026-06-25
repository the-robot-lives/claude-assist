# Authoring core (`TheRobotDraft.Authoring`)

The engine-agnostic heart of the authoring UX from
[`docs/specs/authoring-ux.md`](../../../docs/specs/authoring-ux.md): the command model, the model-mutation
layer, validity rules, and the input-agnostic state machine that **both** the desktop toolbar and the VR
radial drive. This assembly is `noEngineReferences` — pure C#, zero UnityEngine coupling — so the logic
unit-tests as plain code and never depends on the renderer.

## Why a separate, engine-free assembly

The renderer (DOTS / URP / OpenXR) does not exist yet, and the authoring rules must not wait on it. By
depending only on two seams — [`IPacker`](Seams/IPacker.cs) and [`IBubblePicker`](Seams/IBubblePicker.cs) —
the command model, containment/edge legality, spring-loaded modes, and single-step undo are all testable and
correct **today**, and the real renderer drops in behind the seams unchanged.

## Layout

| Folder | What |
|---|---|
| `Model/` | `ElementKind`/`EdgeKind` (§3.1/§4.2), `ElementId`/`EdgeId` (stable keys), `AuthoringModel` (the containment tree + edge list the verbs mutate) |
| `Rules/` | `ContainmentRules` (§3.1 "what's legal in this parent") + `EdgeRules` (§4.4 kind-aware edge legality, cycle check) → `Validity{IsValid, Reason}` for the §B invalid-affordance hover |
| `Commands/` | `IAuthoringCommand` + `UndoStack`. Every verb is one reversible command = one undo step (§0.2): add/connect/re-parent/re-type/re-target/rename/abstract/delete-subtree |
| `Seams/` | `IPacker` (ADR-003: the packer owns position, the user picks the parent), `IBubblePicker` (BVH ray-pick + C1 angular assist), minimal `Float3`/`Ray3` math |
| `State/` | `AuthoringController` — the state machine: modes, spring-loaded commit style, target validity → `AffordanceState` (§5.1), routes all mutation through `UndoStack` |

## Invariants enforced (the load-bearing ones)

- **Placement = pick the parent, never a coordinate** (§0.1 / ADR-003). The model has no xyz; `IPacker`
  positions. There is no free-move — re-parent is the only "move" gesture.
- **Never stranded** (§1): `AuthoringController.Cancel()` always returns to `Select` from any state.
- **Spring-loaded** (§1): one-shot auto-returns to `Select`; sticky stays. Default one-shot.
- **Validity felt before commit** (§3.1/§4.4): commits are refused on an invalid target — no post-drop error.
- **Single-step undo** (§0.2): including delete, which snapshots the whole subtree + incident edges.

## What the renderer/layout side must implement (the seams)

1. **`IPacker`** over the sphere-packing layout engine (rendering-and-vr.md §2.1), off the frame loop.
   `RepackResult` reports ripple extent so the renderer can bound the comfort cross-fade (feasibility **A1**:
   subtree-only, ease ≤300 ms, alpha-fade nodes moving > ~10°).
2. **`IBubblePicker`** over the BVH (rendering-and-vr.md §3.5, O(log n)). `PickValid` must apply the
   **angular magnetic assist** toward valid targets and one-euro ray smoothing, and set `PickResult.Assisted`
   so the UI can show the dwell-to-confirm candidate highlight — the **C1** mitigation, the one gated risk.

## Next (not in this slice)

Input adapters (desktop Input System → toolbar; VR XRI → wrist-anchored radial, F1/F2/F3 + C3 deltas), the
UI Toolkit toolbar panel, the near-field keyboard panel (A2), and the renderer/packer/BVH themselves. Those
need URP + Input System + XRI + Entities added to the manifest (currently a bare uGUI stub) and are
separately sequenced. See `docs/specs/authoring-ux.md` §7 for the feasibility findings that shape them.

## Tests

`Assets/Tests/EditMode/AuthoringCoreTests.cs` — containment + edge legality, add/connect/delete + undo
round-trips, spring-loaded one-shot vs sticky, never-stranded cancel, re-parent guards. Run via
**Window ▸ General ▸ Test Runner ▸ EditMode**.
