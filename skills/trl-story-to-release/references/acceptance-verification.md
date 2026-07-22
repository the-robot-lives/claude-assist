# Acceptance Verification

Phase 5: prove the built story against its acceptance criteria — once per linked persona — then audit style-guide conformance against the frozen checklist and run the persona-derived edge-case battery. Output is `conformance.md` (from `assets/conformance-report-template.md`).

## The Persona × Criteria Matrix

The unit of verification is the **(persona, criterion) pair**, not the criterion. A criterion passed by the expert persona and failed by the novice is a FAIL.

### Matrix construction

| Rule | Detail |
|------|--------|
| One row per pair | 3 criteria × 2 linked personas = 6 rows, no exceptions |
| Walkthrough is embodied | Use the persona's entry point, viewport/device, expertise, and patience — a novice knows only what is on screen |
| Outcomes recorded verbatim | "Found export in 2 clicks" beats "works". Verbatim friction is what makes FAILs actionable |
| Verdicts are ternary | PASS / FAIL / WAIVER-REQUESTED (only the user grants waivers, with rationale logged) |
| FAIL rows block ship | Fix in persona-impact order, re-verify only affected rows |

### Walkthrough procedure per row

```
1. Set context: persona's device/viewport, auth state, first-run vs returning
2. Execute the Given — arrange exactly the criterion's precondition
3. Perform the When — as the persona would (novice: no shortcuts, no docs)
4. Observe the Then — did the criterion's observable outcome occur?
5. Score friction — hesitation >few seconds, mis-clicks, jargon stalls → note
6. Verdict — Then met AND persona succeeded unaided → PASS, else FAIL
```

### Example matrix (US-042, personas P-003 novice admin + P-007 on-call SRE added at grooming)

| Criterion | Persona | Walkthrough result | Style | Edge cases | Verdict |
|-----------|---------|--------------------|-------|-----------|---------|
| AC-1 four metric cards render at /admin | P-003 | Landed from console nav; headline verdict "All systems normal" read in <1s; all 4 labels understood (relabeled p95 helped) | ✓ | — | PASS |
| AC-1 | P-007 | Wanted raw numbers density; got them via card detail; no blocker | ✓ | — | PASS |
| AC-2 cards render ≤2s warm | P-003 | 1.4s measured, skeletons shown meanwhile | ✓ | throttled 3G: 3.9s but skeleton + no layout shift → within criterion (warm session clause) | PASS |
| AC-2 | P-007 | 1.4s | ✓ | — | PASS |
| AC-3 unavailable state explains next step | P-003 | Killed collector; state read "Metrics are still warming up… Check collector status →"; Dana clicked through | ✓ | partial data (2 of 4 metrics) initially rendered blank cards — **FAIL** | FAIL → fixed |
| AC-3 | P-007 | Same state; wanted error detail — link to collector logs satisfied it | ✓ | ✓ after fix | PASS |

The AC-3/P-003 partial-data failure was fixed (per-card unavailable state) and only its rows re-verified.

## Style-Guide Conformance Audit

Walk every row of the frozen `constraints.md` against the built surface:

| Step | Action |
|------|--------|
| 1 | Evaluate each AF/PC/SG row's pass condition literally (grep for hex literals, measure contrast, audit imports, copy review) |
| 2 | Unmet row → deviation-log entry: what deviated, why, verdict **justified** (with rationale) or **fix-required** |
| 3 | Fix-required deviations are fixed before ship; justified ones ship with the log visible in `conformance.md` |
| 4 | Style guide itself proved wrong/gappy → upstream note to the guide owner (trl-user-experience-engineer territory); never edit the guide here |

## Persona-Derived Edge-Case Battery

Derive from the linked personas' constraints — these are the cases generic QA misses:

| Dimension | Derived from | Battery items |
|-----------|--------------|---------------|
| **Accessibility** | AF floor + any persona a11y notes | Keyboard-only full walkthrough; visible focus order; axe scan 0 critical/serious; screen-reader names on interactive elements; reduced-motion honored |
| **Device** | Persona demographics/context | Smallest persona viewport (e.g. 1366×768 laptop, 390px phone); touch targets ≥44px if any persona is touch-primary; throttled network if field/mobile persona |
| **Expertise** | Technical Level | First-run with no docs (novice); efficiency path exists — keyboard/dense mode (expert) |
| **Data** | Criterion Givens + ambiguity log | Empty, partial, error, oversized (1000-row table, 30-char metric values), permission-denied |

Each battery item lands in the matrix's "Edge cases" column of the persona rows it belongs to.

## Exit Criteria

| Condition | Required for ship |
|-----------|-------------------|
| Every matrix row PASS or user-waived | Yes |
| Every deviation justified or fixed | Yes |
| Edge-case battery complete for all linked personas | Yes |
| `conformance.md` written; story checkboxes ticked | Yes |
| Non-blocking friction notes triaged (follow-up stories suggested) | Advisory |

> Proceed to `release-notes-and-rollout.md`. Full run: `worked-example-dashboard-story.md`.
