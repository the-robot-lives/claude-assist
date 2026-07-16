---
id: M2
name: "Training, Evolution & Research"
sequence: 2
depends_on: [M1]
lanes: 3
stories: [US-004, US-007, US-019, US-045, US-046, US-048, US-051, US-052, US-053, US-054, US-055, US-056, US-057, US-058, US-059, US-060]
---

# M2 — Training, Evolution & Research

The Training Gym and the analytics loop that turns raw battles into a learning system. Players
spar against configurable opponents, watch their fighter's behavior evolve, and inspect
reproducible training data; researchers get seeds, exports, and honest model documentation.
Sequenced after M1 because training and analytics consume real battle results and opponents.

## Entry criteria

- M1's exit criteria are met: the core play loop (arena resolution + replay + decision trace)
  produces the battle data this milestone analyzes.
- The M0 replay/decision-trace contract and the M1 arena API are frozen — the gym and analytics
  lanes read training runs and match results through them.

## Exit criteria

- The gym runs reproducible training: `cargo test -p engine training::` exits 0 for seeded,
  reproducible training runs against configurable sparring partners.
- Behavioral analytics render: `npm run test:gym` exits 0 for loss-curve/weight-update
  visualization, node-activation heatmaps, and behavioral run-to-run diffs.
- Research export is complete and honest: `npm run test:research-export` exits 0 for JSON graph
  export with full training history, external-analysis export, and the honest-model-doc surface.
- Balance + patch-notes surfaces exist: `file exists` at `docs/model/honest-ai-model.md` and
  `npm run test:balance` exits 0 for balance-patch preview and build-affecting patch notes.
- All 16 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `cargo test -p engine training::` exits 0 (seeded, reproducible runs)
- [ ] `npm run test:gym` exits 0 (loss curves, heatmaps, behavioral diff)
- [ ] `npm run test:research-export` exits 0
- [ ] `docs/model/honest-ai-model.md` file exists and `npm run test:balance` exits 0
- [ ] All 16 M2 stories' acceptance criteria checked off
- [ ] M3 Entry criteria reviewed and satisfied

## Worker lanes

### L2.A — Training Gym Client
- **Zone / exclusive paths:** `client/gym/`
- **Mission:** The gym front end — choose a sparring partner, run generations, and watch
  behavior evolve with post-match insight.
- **Tasks:**
  - T2.A.1 — Sparring-partner selection and per-run configuration UI (US-007, US-055).
  - T2.A.2 — Loss-curve / weight-update visualization that updates as generations run (US-052).
  - T2.A.3 — Post-match node-activation heatmap review (US-004).
- **Stories delivered:** US-004, US-007, US-052, US-055
- **Contracts:** provides the gym UI. Consumes: L2.B training API, M0 replay contract, L0.D tokens.

### L2.B — Training & Research Backend
- **Zone / exclusive paths:** `backend/training/`, `backend/export/`
- **Mission:** The training runtime and the reproducibility/versioning/export surface that
  serves both players and researchers.
- **Tasks:**
  - T2.B.1 — Seeded, reproducible training runs and batch-run scheduling (US-051, US-056).
  - T2.B.2 — Graph version control with rollback and behavioral diff between runs (US-058, US-057).
  - T2.B.3 — JSON graph export with full training history, external-analysis export, and public
    research-profile/lab attribution (US-053, US-059, US-060).
- **Stories delivered:** US-051, US-053, US-056, US-057, US-058, US-059, US-060
- **Contracts:** provides the training-run + export API [training contract], consumed by L2.A,
  L2.C, and M3 visualization/creator lanes. Consumes: M0 graph + replay contracts.

### L2.C — Analytics, Docs & Balance
- **Zone / exclusive paths:** `client/analytics/`, `backend/balance/`, `docs/model/`
- **Mission:** The honest-AI documentation, the balance/patch-notes surface, and the
  season/replay analytics that keep the meta legible and trustworthy.
- **Tasks:**
  - T2.C.1 — Honest AI model documentation surface (`docs/model/honest-ai-model.md`) (US-054).
  - T2.C.2 — Balance-patch preview/changelogs and patch notes that highlight build-affecting
    changes (US-045, US-019).
  - T2.C.3 — Replay export for content and season-end reward summary + historical archive
    (US-046, US-048).
- **Stories delivered:** US-019, US-045, US-046, US-048, US-054
- **Contracts:** provides the balance/patch feed + honest-model docs. Consumes: L2.B training
  contract, M1 arena API.

## Cross-lane integration tasks

- T2.X.1 (owned by L2.B) — Training-loop proof: a gym run configured in the client (L2.A) is
  executed and versioned by the backend (L2.B), its loss curve and behavioral diff render, and
  a full-history JSON export re-imports and re-resolves identically. Gate:
  `npm run test:e2e:training` exits 0.
