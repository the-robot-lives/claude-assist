# Theme Conformance — {slug} ({date})

Treatise-vs-YAML audit record. Lives at
`projects/{domain}/design/theme/conformance-{slug}.md`, updated at the end of every
tuning session and after every drift audit (`references/verification-and-drift.md`).

- **Treatise**: treatise-{slug}.md @ {rev/date}
- **Theme**: theme-{slug}/ ({n} files) · base chain: {…} → theme-style-guide
- **Audited by / workflow**: {agent/user} / {extract-seeds | tune-facets | add-theme-variant | audit-theme-vs-treatise}
- **Serve state**: {clean | remaining ⚠ listed below}

## Verdict

**{CONFORMANT | DRIFTED → remediated | DRIFTED (remediation pending) | CONTRACT STALE}**

{One-paragraph rationale. CONTRACT STALE = the YAML is right and the treatise is wrong;
tuning is blocked pending revision by trl-user-experience-engineer.}

## 1. Value Trace (YAML → treatise)

Every non-inherited value, its clause, and disposition.

| File : key | Value | Treatise § | Disposition (conformant / orphan / violation) | Action taken |
|------------|-------|-----------|-----------------------------------------------|--------------|
| | | | | |

## 2. Claim Coverage (treatise → YAML)

Every pinned §1-§9 claim: realized, waived, or unrealized. Include §8 left-at-base
entries and §3 exclusions.

| § | Claim (condensed) | Status (realized / waived / unrealized) | Where encoded / waiver rationale |
|---|-------------------|------------------------------------------|----------------------------------|
| | | | |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body text vs surface (≥4.5:1; AAA if committed) | | | | |
| 2 | Secondary/muted text (≥4.5:1) | | | | |
| 3 | Accent as text/UI (≥4.5:1 / ≥3:1 large) | | | | |
| 4 | Semantic classes text-on-tint; not hue-alone | | | | |
| 5 | Meaningful borders (≥3:1) | | | | |
| 6 | Focus indicator (visible, ≥3:1, per §9 spec) | | | | |
| 7 | Mode distinctness | — | | — | |
| 8 | Reduced-motion behavior per §9 | — | — | | |
| 9 | Treatise exclusions sweep (banned literals/hues) | | | | |
| 10 | Validator (no ✗, ⚠ explained) | | | | |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured (before → after) | Result |
|------|------|----------|---------------------------|--------|
| | | | | |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| | | | | |

## 6. Standing Cautions

Re-check these after ANY seed or color-mode change.

| Caution | Trigger to recheck |
|---------|--------------------|
| | |

## 7. Escalations to trl-user-experience-engineer

| # | Issue (treatise defect / revision proposal) | § | Status |
|---|---------------------------------------------|---|--------|
| | | | |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| | | | |
