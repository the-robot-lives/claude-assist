---
id: M0
name: Foundation & Onboarding
sequence: 0
depends_on: []
lanes: 3
stories: [US-039, US-040, US-041, US-042, US-043, US-044, US-045, US-046, US-047, US-048, US-055, US-084, US-085, US-086]
---

# M0 — Foundation & Onboarding

Delivers the launcher, the first-run agent environment, the user/machine profiles, and the
nine YAML data schemas every later milestone reads and writes. This is the sequence's origin:
nothing runs until you can install `the-robot-learns`, launch it, bootstrap
`~/.config/the-robot-learns-kb/`, and have a frozen data-shape contract to build against.

## Entry criteria

- None — this is the sequence's origin point.

## Exit criteria

- `npm install -g the-robot-learns && robot-learns --version` exits 0 on a clean machine
  (US-039).
- A first `robot-learns` run bootstraps `~/.config/the-robot-learns-kb/` containing
  `CLAUDE.md`, all nine `schemas/*.example` files, and empty `knowledge/`, `flashcards/`,
  `quizzes/`, `simulations/`, `projects/`, `sessions/` directories; a second run detects the
  existing config and does **not** overwrite user data (US-040, US-044).
- All nine canonical schema files exist under `template/schemas/` and parse as valid YAML
  (`for f in template/schemas/*.example; do yq e '.' "$f" >/dev/null; done` exits 0)
  (US-041, US-042).
- Guided profile creation writes a `user-profile.yaml` and an auto-detected
  `machine-profile.yaml` that both validate against their schemas (US-041, US-042).
- On a machine without Claude Code, the launcher prints an actionable install path and exits
  non-zero with guidance, never a stack trace (US-043, US-084).
- A second `robot-learns` against a KB already in use refuses to start (lockfile guard) rather
  than clobbering in-flight writes (US-086).
- Every KB write routes through the atomic write-temp-then-rename helper; a simulated
  mid-write failure leaves the prior file byte-for-byte intact (US-085).
- `robot-learns --uninstall` removes the launcher and template but leaves
  `~/.config/the-robot-learns-kb/` data intact (US-048).
- Telemetry defaults to **off**; setup discloses what would be collected and requires explicit
  opt-in before anything is sent (US-055).
- All 14 US-0xx stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `npm install -g the-robot-learns && robot-learns --version` exits 0.
- [ ] First run bootstraps the config dir; second run preserves user data.
- [ ] All nine `template/schemas/*.example` files exist and parse as YAML.
- [ ] Profile creation produces schema-valid `user-profile.yaml` + `machine-profile.yaml`.
- [ ] Missing-Claude-Code path prints guidance and exits non-zero (no stack trace).
- [ ] Concurrent-session lockfile guard blocks a second session.
- [ ] Atomic-write helper survives a simulated mid-write failure with no corruption.
- [ ] `--uninstall` preserves KB data.
- [ ] Telemetry is off by default and opt-in only.
- [ ] All 14 stories' acceptance criteria checked off.
- [ ] M1 Entry criteria reviewed and satisfied.

## Worker lanes

### L0.A — Launcher & Distribution
- **Zone / exclusive paths:** `bin/robot-learns`, `bin/*.sh`, `bin/cli.js`, `package.json`,
  npm publish metadata, the startup lockfile logic.
- **Mission:** Ship the shell + npm launcher that installs cleanly, detects Claude Code,
  guards against concurrent sessions, and uninstalls without destroying data.
- **Tasks:**
  - T0.A.1 — Shell `bin/robot-learns` + npm `the-robot-learns` bin wrapper; pass-through of
    `robot-learns [query...]` (US-039).
  - T0.A.2 — Claude Code presence check at launch: guided install path on absence, clear
    runtime error when unavailable, non-zero exit, no stack trace (US-043, US-084).
  - T0.A.3 — Concurrent-session lockfile: acquire `~/.config/the-robot-learns-kb/.lock` on
    start, refuse a second session, release on exit (US-086).
  - T0.A.4 — `--uninstall` removes launcher/template, preserves KB data (US-048).
- **Stories delivered:** US-039, US-043, US-048, US-084, US-086.
- **Contracts:** provides the launcher CLI surface + lockfile protocol **[C-LAUNCH]**,
  consumed by every later milestone that shells out through `robot-learns`. Consumes: none.

### L0.B — Agent Environment & Bootstrap
- **Zone / exclusive paths:** `template/CLAUDE.md`, `template/.claude/commands/knowledge-base-setup.md`,
  `template/seed/**`, the first-run bootstrap routine, profile-switching logic.
- **Mission:** Author the copy-on-first-run template — the agent brain, the setup command, the
  starter content — and make re-setup and multi-profile switching non-destructive.
- **Tasks:**
  - T0.B.1 — First-run bootstrap: copy `template/` → `~/.config/the-robot-learns-kb/`, create
    the empty data directories (US-040).
  - T0.B.2 — Idempotent re-setup that never destroys existing KB data (US-044).
  - T0.B.3 — Seed the KB with starter topics during onboarding (US-045).
  - T0.B.4 — Welcome tour of the six slash commands (US-046).
  - T0.B.5 — Maintain and switch between named profiles (US-047).
- **Stories delivered:** US-040, US-044, US-045, US-046, US-047.
- **Contracts:** provides the `~/.config/the-robot-learns-kb/` directory layout + agent brain
  **[C-CONFIGDIR]**, consumed by every lane that reads or writes the KB. Consumes: C-LAUNCH.

### L0.C — Profiles, Schemas & Write Substrate
- **Zone / exclusive paths:** `template/schemas/**` (the nine `*.example` files), the shared
  atomic-write helper library, the telemetry opt-in disclosure.
- **Mission:** Freeze the nine data-shape contracts and the write-integrity substrate that all
  downstream reads and writes depend on.
- **Tasks:**
  - T0.C.1 — Author the nine YAML schemas: knowledge-article, user-profile, machine-profile,
    local-preference, learning-plan, flashcard-deck, quiz, quiz-result, session-log (US-041,
    US-042).
  - T0.C.2 — Guided user-profile creation + auto-detected machine profile, both schema-valid
    (US-041, US-042).
  - T0.C.3 — Atomic write-temp-then-rename helper used by every KB writer (US-085).
  - T0.C.4 — Telemetry opt-in with clear disclosure, off by default (US-055).
- **Stories delivered:** US-041, US-042, US-055, US-085.
- **Contracts:** provides the nine YAML schemas **[C-SCHEMAS]** and the atomic-write discipline
  **[C-WRITE]**, consumed by every writer in M1–M5. Consumes: C-CONFIGDIR.

## Cross-lane integration tasks

- T0.X.1 (owned by L0.B) — End-to-end first-run proof: on a clean machine, `robot-learns`
  bootstraps the config dir (C-CONFIGDIR), lands all nine schemas (C-SCHEMAS), acquires the
  lock (C-LAUNCH), writes a profile through the atomic helper (C-WRITE), and a second launch
  preserves everything — one flow exercising all three lanes.
