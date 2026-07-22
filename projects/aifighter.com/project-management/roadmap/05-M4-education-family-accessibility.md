---
id: M4
name: "Education, Family, Accessibility & Launch Readiness"
sequence: 4
depends_on: [M2, M3]
lanes: 4
stories: [US-011, US-013, US-028, US-029, US-030, US-031, US-032, US-033, US-035, US-036, US-038, US-040, US-066, US-068, US-069, US-070, US-072, US-075, US-076, US-077, US-078, US-079, US-080, US-086]
---

# M4 — Education, Family, Accessibility & Launch Readiness

The hardening milestone. It makes the finished product safe for classrooms, welcoming to
families, fully usable with assistive technology, and ready for public launch with moderation,
progression, and competition polish. Sequenced last because accessibility hardening and
content moderation act on screens and community surfaces that must already exist (M1–M3).

## Entry criteria

- M2's and M3's exit criteria are met: the full screen inventory — studio, arena, gym,
  laboratory, community, creator — exists to be made accessible, safe, and classroom-ready.
- The M0 design-system baseline (touch targets, reduced motion, non-color state, color-vision
  tokens) is frozen — accessibility hardening extends it rather than redefining it.

## Exit criteria

- Classroom tooling works under safeguards: `npm run test:classroom` exits 0 for sandbox mode,
  COPPA student accounts, safe-mode content filter, training-data export, and free-tier
  full-feature access.
- Moderation + family mode are enforced: `npm run test:moderation` exits 0 for the
  build/guide flagging pipeline, the cosmetics moderation queue, and family-friendly content mode.
- Accessibility passes end-to-end: `npm run test:a11y` exits 0 for VoiceOver live regions,
  list-based node connection, switch-control navigation, semantic labels, accessible insight
  report, and haptic-only feedback — with zero critical axe violations.
- Launch readiness holds: `npm run test:launch` exits 0 for no-FOMO tournament structure,
  seasonal ladder cosmetics, clan/shared-resource access, and creator early-access gating.
- All 24 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `npm run test:classroom` exits 0
- [ ] `npm run test:moderation` exits 0
- [ ] `npm run test:a11y` exits 0 (zero critical axe violations)
- [ ] `npm run test:launch` exits 0
- [ ] All 24 M4 stories' acceptance criteria checked off
- [ ] Launch sign-off recorded

## Worker lanes

### L4.A — Classroom & Education
- **Zone / exclusive paths:** `client/classroom/`, `backend/education/`
- **Mission:** Make AI Fighter a teaching tool — sandboxed, standards-friendly, and free for
  education.
- **Tasks:**
  - T4.A.1 — Classroom sandbox mode and COPPA-compliant student accounts (US-028, US-029).
  - T4.A.2 — Node-concept glossary integration, lesson-plan template library, and student
    tournament bracket (US-031, US-032, US-033).
  - T4.A.3 — Training-data export for coursework, heatmap export for assignments, and free-tier
    full-feature access for education (US-030, US-040, US-038).
- **Stories delivered:** US-028, US-029, US-030, US-031, US-032, US-033, US-038, US-040
- **Contracts:** consumes M2 export contract, M0 studio + design system. Provides the education
  surface.

### L4.B — Safety, Moderation & Family Mode
- **Zone / exclusive paths:** `backend/moderation/`, `client/safety/`
- **Mission:** The trust-and-safety layer — flagging, moderation queues, and content modes that
  protect students, families, and the community.
- **Tasks:**
  - T4.B.1 — Build-and-guide flagging pipeline and safe-mode content filter for classrooms
    (US-035, US-036).
  - T4.B.2 — Content-moderation queue for community cosmetics (US-079).
  - T4.B.3 — Family-friendly content mode and shared fighter viewing for co-play (US-066, US-068).
- **Stories delivered:** US-035, US-036, US-066, US-068, US-079
- **Contracts:** consumes M3 community/creator surfaces (moderates them), M0 design system.
  Provides the moderation API. Supports: L3.A community feed and L4.A classrooms.

### L4.C — Accessibility Hardening
- **Zone / exclusive paths:** `client/a11y/`, `test/a11y/`, and per-screen accessibility
  annotation files (`*.a11y.md` beside each screen component)
- **Mission:** Take the M0 baseline to full assistive-technology support across every screen
  built in M1–M3. This lane is cross-cutting by nature, so it runs after the other M4 lanes'
  screens are stable and owns the a11y audit harness plus per-screen annotation files rather
  than the screens themselves.
- **Tasks:**
  - T4.C.1 — VoiceOver live regions for battle state and semantic screen-reader labels on graph
    nodes (US-069, US-075).
  - T4.C.2 — List-based node-connection interface and switch-control full-app navigation
    (US-070, US-072).
  - T4.C.3 — Accessible post-battle insight report, VoiceOver-navigable template gallery, and
    haptic-only battle feedback (US-076, US-078, US-080).
- **Stories delivered:** US-069, US-070, US-072, US-075, US-076, US-078, US-080
- **Contracts:** consumes M0 design-system a11y primitives and every M1–M3 screen. Provides the
  a11y audit harness + conformance annotations.

### L4.D — Launch Readiness: Progression & Competition Polish
- **Zone / exclusive paths:** `client/season/`, `backend/tournament/`, `client/clan/`
- **Mission:** The retention-and-fairness polish that gates public launch — anti-FOMO
  competition structure, seasonal progression, clans, and creator early access.
- **Tasks:**
  - T4.D.1 — No-FOMO tournament structure that never punishes intermittent players (US-077).
  - T4.D.2 — Seasonal-ladder cosmetic rewards and clan join + shared build resources
    (US-011, US-013).
  - T4.D.3 — Early-access preview gating for enrolled creators (US-086).
- **Stories delivered:** US-011, US-013, US-077, US-086
- **Contracts:** consumes M1 arena API, M2 season summary, M3 creator programs. Provides the
  season/tournament/clan surfaces.

## Cross-lane integration tasks

- T4.X.1 (owned by L4.C) — Launch-readiness proof: a full journey — a student account (L4.A)
  in family/safe mode (L4.B) completes onboarding, a battle, and a replay entirely via
  VoiceOver and switch control (L4.C), inside a no-FOMO seasonal event (L4.D) — passes with
  zero critical accessibility violations. Gate: `npm run test:e2e:launch` exits 0.
