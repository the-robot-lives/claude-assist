# Seed Extraction Worksheet — {slug}

Fill during treatise intake (`references/treatise-intake.md`). One row per treatise
claim; every planned YAML value must trace to a row. Claim types: **pinned** (encode
exactly), **delegated** (leave to the cascade — record as a non-action), **verification**
(a check, not a value), **undecidable** (question for the treatise author — do not guess).

- **Treatise**: projects/{domain}/design/theme/treatise-{slug}.md
- **Theme dir**: projects/{domain}/design/theme/theme-{slug}/
- **Intake by / date**: {…}

## A. Seed Capture (§3, §4, §6 → style-guide.vars.yaml)

| Seed | Treatise § + quote (condensed) | Value | Range/band allowed | Verify after change |
|------|-------------------------------|-------|--------------------|---------------------|
| white | | | | |
| black | | | | |
| brand-red (primary accent) | | | | |
| brand-blue (secondary) | | *unset if single-accent* | | |
| brand-yellow (tertiary) | | *unset if single-accent* | | |
| success | | | | |
| warning | | | | |
| error | | | | |
| info | | | | |
| font-sans | | | matches font-url? ☐ | |
| font-mono | | | matches font-url? ☐ | |
| radius | | | exceptions (chips etc.)? | |
| (layout: unit / other) | | *only on explicit §5 claim* | | |

## B. Non-Seed Claims (§1-§9 → facets / snippets / checks)

| § | Claim (quote) | Type | Encoding level (seed / mode / facet / snippet / check) | Target file : key | Value / action |
|---|---------------|------|--------------------------------------------------------|-------------------|----------------|
| | | | | | |
| | | | | | |
| | | | | | |

## C. Deliberate Non-Actions (delegations + exclusions)

| § | Delegation / exclusion | What you will NOT do |
|---|------------------------|----------------------|
| | e.g. "gray ramp is the engine's to derive" | do not hand-set gray-* tokens |
| | e.g. "no secondary brand hue" | leave brand-blue/brand-yellow unset |
| | e.g. §8 "left at base: tables, toasts…" | no overrides for listed components |

## D. §9 Verification List (copy every near-the-line pair)

| Pair / check | Mode | Threshold | First measurement |
|--------------|------|-----------|-------------------|
| | | | |
| | | | |

## E. §10 Reconciliation

| Appendix row | In plan? | Discrepancy / resolution |
|--------------|----------|--------------------------|
| | ☐ | |

## F. Undecidable Claims → Questions for trl-user-experience-engineer

| § | Bare/ambiguous claim | Question |
|---|----------------------|----------|
| | | |

## G. Resulting File Plan

| File | Ship? | Justifying rows above |
|------|-------|-----------------------|
| style-guide.meta.yaml | yes | §1 |
| style-guide.vars.yaml | yes | A |
| branding.yaml | yes | §1 |
| style-guide.color-modes.yaml | yes | §3 mode strategy |
| {…} | | |
