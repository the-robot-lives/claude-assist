# Treatise Intake

> How to parse a theme treatise into an actionable delta list before touching any YAML. The treatise is the contract; intake is where you read the contract line by line and decide what each clause costs in YAML.

---

## 1. What a Treatise Is

A theme treatise is the design-theory treatment authored by trl-user-experience-engineer
(format spec: that skill's `references/outputs/theme-treatise.md`). It lives at:

```
projects/{domain}/design/theme/
  treatise-{slug}.md        ← the contract
  theme-{slug}/             ← the YAML you produce/tune against it
```

It contains **exactly 10 numbered sections, in canonical order** — never renamed,
renumbered, merged, or omitted. You navigate by number:

| § | Section | What it pins |
|---|---------|--------------|
| 1 | Identity | intent, perception, audience, tone, keywords (+ variant note for child themes) |
| 2 | References & Anchors | 2-4 anchors with what to borrow; 1-3 anti-references with the rejected quality |
| 3 | Color Story | temperature/register, hue relationships, neutral strategy, semantic mapping, contrast stance, mode strategy |
| 4 | Typographic Voice | families with rationale, scale character/ratio, weight usage, rhythm |
| 5 | Space & Density | spacing philosophy, density target (reference screen), responsive stance |
| 6 | Shape & Surface | radius language, borders, elevation, texture/gradient policy |
| 7 | Motion & Feedback | animation character, duration/easing bands, interaction states |
| 8 | Component Inflections | buttons, inputs, cards, navigation minimum — plus explicit "left at base" list |
| 9 | Accessibility Commitments | WCAG target, contrast minimums, focus visibility, reduced motion |
| 10 | Facet Mapping Appendix | advisory table: §1-§9 decisions → engine facets + seed hints |

If a document is missing sections, has bare adjectives everywhere, or renumbers —
**stop and hand back to trl-user-experience-engineer**. Do not repair a treatise
yourself; you may only flag what makes it unexecutable.

## 2. The Intake Procedure

```
READ  → CLASSIFY each claim → RECORD deltas → RECONCILE with §10 → PLAN files
```

### Step 1 — Read for the three claim types

Every treatise claim is one of:

| Claim type | Example | Your obligation |
|---|---|---|
| **Pinned** (measurable/exclusion) | "accent `#e8763a` ±5° hue", "no pills", "nothing exceeds 250ms" | Encode exactly; verify after every later change |
| **Delegated** (degree of freedom) | "exact gray ramp is the engine's to derive from the white/black seeds" | Let the cascade decide; do NOT override |
| **Verification** (§9 commitments) | "secondary text must stay ≥ 4.5:1" | Not a YAML value — a check you run in every mode |

If a claim is none of these (a bare adjective: "clean", "bold"), it is **undecidable** —
list it in your intake notes as a question for the treatise author, and proceed only on
the decidable claims.

### Step 2 — Classify against the cascade

For each pinned claim, decide the cheapest encoding level (see `seed-extraction.md`):

1. **Seed** — expressible as one of the ~12 vars.yaml seeds → always prefer
2. **Facet override** — the cascade derives the wrong thing for this design → override the facet
3. **Snippet** — behavior/state CSS the facets don't model (motion, hover mechanics) → `css-snippets` (accumulates)
4. **Out of scope** — app implementation detail → note for trl-react-engineer handoff

### Step 3 — Record deltas on the worksheet

Fill `assets/seed-extraction-worksheet.md`: one row per claim — treatise section,
claim quote, encoding level, target file/key, value, verification note.

### Step 4 — Reconcile with §10

The Facet Mapping Appendix is **advisory**: you may deviate where the cascade produces a
better result, but must preserve the stated intent. Diff your plan against §10:

- Appendix row you didn't plan → you missed a decision; go back to the body section
- Your plan has a file the appendix lacks → fine, if it traces to a body claim; suspicious otherwise
- Appendix contradicts the body → the body wins; note the discrepancy in the conformance report

### Step 5 — Plan the file list

Output of intake is a minimal file plan. Typical shapes:

| Theme profile | Files planned |
|---|---|
| Chromatic-only delta (like ember) | `meta`, `vars`, `branding`, `color-modes` + `css-snippets` for motion/components |
| Full identity theme | above + `typography`, `color-palette`, `semantic-classes`, `spacing`/`page-layouts` |
| Mode variant (child theme) | `meta` (base-theme: parent), `color-modes`, mode-relevant seeds, `scoped-vars` |

Never plan a file "for completeness." A file exists because a treatise claim demands it.

## 3. Section-by-Section Extraction Notes

- **§1 → `branding.yaml` + `style-guide.meta.yaml`.** Mechanical: intent/perception/audience/tone/keywords copy verbatim. Variant note (if present) sets `base-theme` and scopes the whole intake to deltas.
- **§2 → constraints, not YAML.** Anchors tell you which existing style spec's numbers to reach for when the treatise gives a range; anti-references are rejection tests for your candidate values ("would this read as CRT nostalgia?").
- **§3 → seeds first.** Neutral strategy sets `white`/`black`; hue relationships set the brand seeds (and tell you which brand slots to leave EMPTY — "no secondary hue" means do not populate `brand-blue`); semantic mapping sets the four semantic seeds; mode strategy dictates `color-modes.yaml` and whether a variant theme is warranted; contrast stance parameterizes the §9 checks.
- **§4 → `font-sans`/`font-mono` seeds + `branding.yaml` `font-url`** always; `typography.yaml` only if the scale/weights deviate from default (a stated ratio like "~1.2 tight" usually does).
- **§5 → usually inherit.** Only override `spacing.yaml`/`page-layouts.yaml` when the density target can't be met by the base's 8px scale and container widths. Encode padding/gutter philosophy in component snippets when it's per-surface.
- **§6 → `radius` seed** carries most of it. Elevation-by-tone, border policies, and sanctioned gradients become `css-snippets`/`scoped-vars`.
- **§7 → `css-snippets` (+ `scoped-vars` for duration/easing custom props).** Always encode the `prefers-reduced-motion` guard the §9 section demands.
- **§8 → component-level vars in `vars.yaml`, `semantic-classes.yaml`, `css-snippets`.** The explicit "left at base defaults" list is as binding as the overrides — do not style what §8 says to leave alone.
- **§9 → the verification matrix inputs.** Copy every "known near-the-line pair" into the conformance report's check list before tuning starts.
- **§10 → cross-check only** (step 4 above). Never treat it as the source of a decision.

## 4. Worked Example: Intake of Two §3 Paragraphs

Treatise excerpt (`treatise-ember.md` §3):

> **Neutral strategy:** Warm charcoals, not grays. Canvas ~`#1a1512` … The gray ramp the
> engine derives from white/black seeds must be re-seeded: "black" seed is `#141110`,
> "white" seed is `#f5efe8` (warm off-white) so every derived step inherits the tint.
> Pure `#000`/`#fff` never appear.
>
> **Hue relationships:** Monochrome-warm + single accent. Accent is ember orange `#e8763a`
> (±5° hue, ±8% saturation acceptable). No secondary brand hue…

Intake rows produced:

| § | Claim | Type | Level | Target | Value / action | Verify |
|---|-------|------|-------|--------|----------------|--------|
| 3 | white seed `#f5efe8` | pinned | seed | `vars.yaml` Surfaces `white` | `"#f5efe8"` | light-mode text ratios after change |
| 3 | black seed `#141110` | pinned | seed | `vars.yaml` Surfaces `black` | `"#141110"` | dark surfaces carry visible warmth |
| 3 | pure #000/#fff never appear | pinned (exclusion) | verification | grep generated CSS / rendered page | reject any literal `#000`/`#fff` in overrides | every serve pass |
| 3 | gray ramp derived from seeds | delegated | — | (none) | do NOT hand-set gray-50…gray-900 | — |
| 3 | accent `#e8763a` ±5°/±8% sat | pinned (range) | seed | `vars.yaml` Brand `brand-red` | `"#e8763a"`; tuning may move within band | contrast as text ≈5.4:1 (from §9) |
| 3 | no secondary brand hue | pinned (exclusion) | seed | `vars.yaml` Brand | leave `brand-blue`/`brand-yellow` unset (inherit is irrelevant — never referenced) | no second saturated hue on screen |

Note the pattern: two paragraphs yielded four YAML actions, one deliberate non-action,
and two standing verification checks. That ratio — more constraints than values — is
normal for a good treatise.

## 5. Intake Output Checklist

- [ ] Every §1-§9 claim classified (pinned / delegated / verification / undecidable)
- [ ] Undecidable claims listed as questions, not guessed at
- [ ] Worksheet rows trace each planned value to a section quote
- [ ] §10 reconciled; discrepancies noted
- [ ] File plan is minimal — each file justified by a claim
- [ ] §9 near-the-line pairs copied into the verification list
- [ ] "Left at base" components from §8 recorded as do-not-touch
