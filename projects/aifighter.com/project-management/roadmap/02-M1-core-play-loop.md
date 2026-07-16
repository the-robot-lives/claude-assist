---
id: M1
name: "Core Play Loop"
sequence: 1
depends_on: [M0]
lanes: 3
stories: [US-008, US-009, US-012, US-014, US-016, US-018, US-021, US-022, US-023, US-034, US-041, US-042, US-043, US-044, US-047, US-049, US-050, US-063, US-065, US-067]
---

# M1 — Core Play Loop

The first playable end-to-end loop. A new player onboards with a guided tutorial, deploys or
tweaks a fighter, submits it to the ranked arena, the battle resolves asynchronously, and the
player watches the replay with the decision overlay. This is the smallest complete product
loop and the spine every later milestone extends.

## Entry criteria

- M0's exit criteria are met: the frozen `graph.schema.json`, the deterministic engine, the
  decision-trace/replay format, and the design-system baseline are all merged.
- The `contracts/api/graph/` graph contract and the M0 replay contract are frozen — the arena
  and replay lanes key against them.

## Exit criteria

- Onboarding completes to a working fighter: `npm run test:onboarding` exits 0 for the guided
  tutorial that ends with a deployable fighter and template deploy.
- The async arena round-trips: `npm run test:arena-loop` exits 0 for submit → server-side
  resolve → notification → replay-ready.
- The replay viewer plays the M0 decision trace: `npm run test:replay` exits 0 for
  playback-speed/frame-step, decision-overlay toggle, and build-metadata panel.
- Matchmaking + ranking are live: `npm run test:matchmaking` exits 0 for ELO placement,
  percentile leaderboard, anti-smurf detection, and queue-status estimate.
- All 20 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `npm run test:onboarding` exits 0
- [ ] `npm run test:arena-loop` exits 0
- [ ] `npm run test:replay` exits 0
- [ ] `npm run test:matchmaking` exits 0
- [ ] All 20 M1 stories' acceptance criteria checked off
- [ ] M2 Entry criteria reviewed and satisfied

## Worker lanes

### L1.A — Onboarding & Studio Flows
- **Zone / exclusive paths:** `client/onboarding/`, `client/studio/flows/`
- **Mission:** Get a first-time player from install to a fighter they submitted, and give the
  post-match tweak-and-retry hook that drives the core loop.
- **Tasks:**
  - T1.A.1 — Guided tutorial that ends with a working, deployable fighter (US-008).
  - T1.A.2 — Starter-template browse-and-deploy and daily-challenge entry (US-009, US-018).
  - T1.A.3 — Post-loss specific-tips surface and submit-and-notify flow (US-012, US-014).
  - T1.A.4 — Quick-tweak suggestion card after a battle to close the loop back to the editor
    (US-063).
- **Stories delivered:** US-008, US-009, US-012, US-014, US-018, US-063
- **Contracts:** provides onboarding entry points. Consumes: M0 graph contract + Studio, L1.C
  submit/notify API, L0.D tokens.

### L1.B — Arena Client & Replay Viewer
- **Zone / exclusive paths:** `client/arena/`, `client/replay/`
- **Mission:** The compete-and-review half of the loop — the arena front end and the replay
  theater that renders the engine's decision trace.
- **Tasks:**
  - T1.B.1 — Replay playback with speed + frame-step controls and a glanceable battle summary
    (US-034, US-067).
  - T1.B.2 — Decision-overlay toggle/filtering over the M0 decision trace, plus a build-metadata
    stats panel (US-022, US-023).
  - T1.B.3 — Replay bookmarking/annotation and the "why was I matched" explainer (US-021, US-016).
- **Stories delivered:** US-016, US-021, US-022, US-023, US-034, US-067
- **Contracts:** provides the replay-view components [consumed by M3 theater/creator lanes].
  Consumes: M0 replay contract, L1.C matchmaking API, L0.D tokens.

### L1.C — Matchmaking, ELO & Notifications
- **Zone / exclusive paths:** `backend/matchmaking/`, `backend/ranking/`, `backend/notify/`
- **Mission:** The server-side arena — async submission, ELO, leaderboards, fair matchmaking,
  and the notifications that make async play feel responsive.
- **Tasks:**
  - T1.C.1 — Async match submission + fast resolution + resolve notification; multiple fighter
    slots (US-043, US-042).
  - T1.C.2 — Seasonal ELO, percentile leaderboard, per-match stat breakdown, win-rate by
    opponent tier (US-041, US-047, US-049).
  - T1.C.3 — Anti-smurf detection, frequency-aware matchmaking, and queue status/wait-time
    estimate (US-044, US-065, US-050).
- **Stories delivered:** US-041, US-042, US-043, US-044, US-047, US-049, US-050, US-065
- **Contracts:** provides the arena/matchmaking API + notification format [arena contract],
  consumed by L1.A, L1.B, and M2/M4 competition lanes. Consumes: M0 replay contract.

## Cross-lane integration tasks

- T1.X.1 (owned by L1.B) — Full-loop proof: a fighter built in onboarding (L1.A) is submitted
  through the arena API (L1.C), resolved by the M0 engine, and its replay renders with the
  decision overlay (L1.B) plus a resolve notification. Gate: `npm run test:e2e:core-loop`
  exits 0.
