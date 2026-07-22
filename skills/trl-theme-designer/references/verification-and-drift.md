# Verification & Drift

> The tuning loop's back half: serving the theme, clearing the validator punch list, running the mode-verification matrix against the treatise's §9 commitments, and auditing drift between treatise and YAML. A theme isn't done until every mode passes and the conformance note is written.

---

## 1. The Serve Loop

```bash
# Point at the PARENT directory holding your theme-* folders:
npx @noizu/styleguide serve projects/{domain}/design/theme/
# Flags: --port <n>   --clean (rebuild stale viewer cache after package upgrades)
```

What the launcher does: ensures the canonical base theme (`theme-style-guide`) is present
(auto-copies it — leave it alone, never hand-author or edit it), symlinks your themes into
its cached viewer (`~/.cache/styleguide-viewer/`), generates per-theme CSS, starts
Next.js on `http://localhost:3000`. **Never copy or symlink themes into
`styleguide-engine/app/src/config/`** — hosting is always launcher-managed
(alternatives: `./serve-project.sh {domain}` with a cloned engine; `npm run regen` +
`npm run dev` for project-local hosting — trl-react-engineer territory).

Requirements: Node 18+, `.npmrc` resolving the `@noizu` scope to `npm.noizu.com`.

### The validation punch list

Both the console and an in-viewer **ConfigWarnings alert card** report problems. Treat
every line as a punch-list item — errors first, then warnings:

| Marker | Meaning | Examples & fixes |
|---|---|---|
| `✗` (red) | breaks rendering — fix before anything else | missing `slug` (routing breaks); empty `vars.groups` (page unstyled) |
| `⚠` (amber) | degrades rendering | empty var group → fill or delete; snippet `target-section` not in `page-sections` → add the id or fix the snippet; `color-modes missing 'light'/'dark' map` → populate both; incomplete semantic class → fill `class`/`accent-style`/`vars.accent` |

**Done = no `✗` and no `⚠`** — or each surviving `⚠` is understood, intentional, and
recorded in the conformance note.

### Iteration cadence

Serve stays running; YAML edits require a CSS regen (rerun serve, or the launcher's
watch where available). Tune in small batches — one treatise section per round — and
eyeball the affected viewer sections (token browser after seed changes; buttons/cards
after §8 changes) before moving on. After upgrading `@noizu/styleguide`, rerun with
`--clean` before trusting anything you see.

## 2. Mode-Verification Matrix

Run the full matrix at the end of every tuning session, in this order: primary mode →
secondary mode → forced-colors/high-contrast. Use the viewer's ColorModeToggle for
light/dark; emulate `forced-colors: active` and `prefers-reduced-motion` in devtools
rendering settings.

| # | Check | How | Threshold |
|---|---|---|---|
| 1 | Body text vs surface | contrast-check `text` × `surface` per mode | ≥ 4.5:1 (≥ 7:1 where §9 commits AAA) |
| 2 | Secondary/muted text vs surfaces | same, incl. `surface-alt` | ≥ 4.5:1 — the classic dark-mode failure |
| 3 | Accent as text/UI on each surface | accent × surface, both modes | ≥ 4.5:1 body-size; ≥ 3:1 large text & UI |
| 4 | Semantic classes | each `vars.color` × `vars.background` (tints!) | ≥ 4.5:1; states not distinguished by hue alone |
| 5 | Meaningful borders / component boundaries | `border`/`border-strong` × surface | ≥ 3:1 for boundaries that carry meaning (inputs); decorative dividers exempt but must match treatise's stance |
| 6 | Focus indicator | tab through buttons/inputs/nav in viewer | visible on every element, ≥ 3:1 vs all surface steps, matches §9 spec |
| 7 | Mode distinctness | toggle modes | genuinely distinct render (identical modes only if treatise says so) |
| 8 | Reduced motion | emulate `prefers-reduced-motion: reduce` | everything §9 says is disabled IS disabled; static fallbacks present |
| 9 | Treatise exclusions | visual sweep with §2 anti-references + §3 exclusions in hand | no `#000`/`#fff` where banned, no forbidden second saturated hue, etc. |
| 10 | Validator | console + alert card | no `✗`, no unexplained `⚠` |

Contrast math and the node one-liner: `color-theory-for-tuning.md` §5. Every §9
"near-the-line pair" the treatise names gets an explicit row in the conformance report
with measured before/after ratios.

## 3. Treatise-Drift Audit

Drift accumulates from both directions: ad-hoc YAML edits nobody traced to the treatise,
and treatise revisions nobody propagated to YAML. Audit whenever either file has changed
since the last conformance note, and before any variant work.

### Procedure

1. **Inventory the YAML.** List every file in `theme-{slug}/` and every non-inherited value (facet keys, seeds, snippets, scoped-vars).
2. **Trace each value to a treatise clause.** Three outcomes per value:
   - **Conformant** — traces to a §1-§9 claim (cite the section)
   - **Orphan** — no treatise basis. Either revert it, or (if it's actually right) hand the decision back to trl-user-experience-engineer for treatise inclusion
   - **Violation** — contradicts a claim. Fix the YAML, unless the value exists because the claim proved wrong in practice — then escalate the claim
3. **Sweep the treatise for unrealized claims.** Walk §1-§9; every pinned claim must be encoded or consciously waived. §8's "left at base" list counts: styling a component the treatise reserved is drift too.
4. **Re-run the mode matrix** (§2 above) — §9 commitments are claims like any other.
5. **Write/update the conformance note** (`conformance-{slug}.md`, template: `assets/theme-conformance-report.md`).

### Verdicts

| Verdict | Criteria |
|---|---|
| **CONFORMANT** | all values trace; all claims realized or waived-with-rationale; matrix passes |
| **DRIFTED** | orphans or unrealized claims exist; remediation list attached |
| **CONTRACT STALE** | the YAML is right and the treatise is wrong — block further tuning until UXE revises the treatise (the treatise is the intent of record; "one of them is a bug") |

## 4. Worked Example: A Drift Audit Round on Ember

Trigger: two weeks of ad-hoc tweaks; treatise unchanged. Audit findings:

| Item | Finding | Disposition |
|---|---|---|
| `color-modes.dark.text-secondary: "#b8ab9d"` | traces to §9 contrast fix (5.4:1), noted in conformance | conformant |
| `css-snippets: card-hover-glow` (12px ember blur on card hover) | no treatise basis; §6 says shadows "only under overlays"; §2 anti-references CRT glow | **violation — removed**; hover reverts to §7's elevation-step lighten |
| `vars.yaml` Layout `radius: "5px"` | orphan — someone split the difference during review; treatise pins 4px base, 6px max | reverted to `4px`; the review comment ("cards feel sharp") escalated to UXE as a possible §6 revision |
| §7 reduced-motion guard | claim realized (pulse disabled, static dot fallback) | conformant |
| §3 "pure #000/#fff never appear" | grep of generated CSS found `#fff` in an old button snippet | **violation — fixed** to `var(--white)` |
| §8 tables/toasts left at base | confirmed no table/toast overrides shipped | conformant |

Matrix re-run: all rows pass; ember-as-body-text still flagged (5.4:1 — safe for UI/large
only) and remains a standing caution in the report. Verdict: **DRIFTED → remediated →
CONFORMANT**, conformance note updated with the two removals and the escalated radius
question.

## 5. Session Exit Checklist

- [ ] Serve output clean (no `✗`, `⚠` all explained)
- [ ] Mode matrix run in full since the last YAML change
- [ ] §9 near-the-line pairs re-measured and recorded
- [ ] Every value added this session traces to a treatise clause
- [ ] Conformance note updated (values changed, ratios, waivers, escalations)
- [ ] Escalations actually sent back to trl-user-experience-engineer, not just noted
