# stage-b-treatises.md (version: 1)

Stage B — score existing themes, author enough new theme treatises to reach 7 effective
directions, and allocate screens across all of them for Stage C to render. Self-contained:
this file + your state file + spawn params + the repo's own committed reference docs (fair
game to read — the pipeline plan file is not).

## Params (from your spawn prompt)

- `project` — the slug under `projects/{project}/`
- `eval`, `media` — informational only; Stage B does no rendering

## 0. Setup

1. Read `docs/pipelines/project-uplift/state/{project}.yaml` first — `census.existing_named_themes`
   lists what's already on disk; `roster.yaml`'s per-project `themes:` block (if you have repo
   access to read it — you do, it's a committed file, just not the plan) has the full paths.
2. Set `stage_b.status: in-progress` in the state file now, uncommitted.
3. Do **not** create a tobor session. No skill is invoked for this stage — instead, **read**
   `skills/trl-user-experience-engineer/references/outputs/theme-treatise.md` in full. It is
   the canonical treatise contract and includes a complete worked example (`treatise-ember.md`)
   showing the depth and precision expected — read that worked example before drafting your
   own; it is the calibration reference for "executable" vs "vague" claims.
4. Read the project's `README.md`, `project-management/personas/index.yaml` and
   `project-management/user-stories/index.yaml` (Stage A should already have produced solid
   versions of these — if they look thin or missing, note it in your report but proceed with
   what exists), and every existing `design/theme*/theme-*/` directory's YAML files
   (`style-guide.vars.yaml`, `branding.yaml`, `style-guide.color-modes.yaml` at minimum).

## 1. Similitude gate — score existing themes, decide how many new ones you need

Target: **7 effective theme directions** per project, existing themes count toward this,
weighted by how distinct they actually are from each other (a project with 4 near-identical
"dark mode" variants doesn't really have 4 effective directions).

For each pair of existing named themes `i, j` (excluding any `theme-style-guide` base
copies), score similitude `s(i,j) ∈ [0,1]` by eye across seeds (accent hue/value), palette
temperature, typography family choice, radius/shape language, and branding tone/keywords —
`0` = no meaningful resemblance, `1` = essentially the same theme. Then:

```
E = Σ_i [ Σ_{j≠i} (1 − s(i,j)) ] / (n − 1)         (n = existing theme count; n=1 ⇒ E = 1; n=0 ⇒ E = 0)
```

Author `ceil(7 − E)` new theme directions, deliberately chosen to be **low-similitude**
against both the existing themes and each other (if you're inventing 3 new ones, don't invent
3 flavors of the same idea — spread them across genuinely different aesthetic territory using
different anchors/anti-references per §2 of the contract).

Record the pairwise matrix and the E calculation in `design/theme/THEMES.md` (create it if it
doesn't exist) — a simple markdown table is fine. This file is what `verify.md` §B checks for
(`grep "E *="`).

If a project has **zero** existing named themes (n=0, E=0), you're authoring all `ceil(7-0)=7`
from scratch — skip the matrix (nothing to score) but still write `THEMES.md` stating `E = 0`
and the 7 fresh directions you chose and why they're mutually distinct.

## 2. Write treatises — one per theme, new AND existing

**Every** theme this project ends up with — the ones you're inventing and the ones that
already exist as YAML — gets a treatise at `design/theme/treatise-{slug}.md`, sibling to its
`design/theme/theme-{slug}/` directory (slug matches).

**For existing themes: reverse-engineer.** Read the theme's actual YAML values (seed colors,
fonts, radius, color-modes) and write the treatise that explains and justifies what's already
there — work backward from implementation to intent. If a value looks arbitrary or
inconsistent (e.g., a radius that doesn't match anything else in the theme), say so honestly
in the relevant section rather than inventing a rationale that isn't real; that's useful
signal for the human reviewing the pilot digest.

**For new themes: forward.** Write intent first (§1-§2), let the color/type/shape decisions
in §3-§8 follow from it.

### File header

```markdown
---
slug: {slug}
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — {Theme Name}

Theme: `theme-{slug}/` · Base: `theme-style-guide` · Status: sketch
```

`status: sketch` at this stage; Stage C flips it to `full` after the render/reflect pass
(and bumps `revision:`). This frontmatter block is what `verify.md` §C checks — don't omit it.

### The 10 required sections, in order, exact headings

Every treatise has **exactly** these 10 numbered `##` sections, no renaming/merging/omitting
(a fine-tuner in Stage C navigates by number):

1. **`## 1. Identity`** — Intent, Perception, Audience, Tone, Keywords (4-6 words); for
   variants also: base theme, what splits it off, one-sentence delta.
2. **`## 2. References & Anchors`** — 2-4 anchors (existing products/sites/style specs, each
   with *what specifically* to borrow) + **1-3 anti-references required** (specific rejected
   qualities, not just names — "not X" is not enough, say what about X is wrong).
3. **`## 3. Color Story`** — temperature/register, hue relationships, neutral strategy
   (tinted vs pure gray + seed hints), semantic mapping philosophy + collision rules,
   contrast stance, mode strategy (light/dark/high-contrast — cover all three even if the
   answer for one is "doesn't exist in v1").
4. **`## 4. Typographic Voice`** — families + why each, scale character + ratio, weight
   usage, rhythm (line-height, measure, where mono appears/never appears).
5. **`## 5. Space & Density`** — spacing philosophy + base unit, density target (a concrete
   reference screen + how much it holds), responsive stance (what compresses first, what's
   protected).
6. **`## 6. Shape & Surface`** — radius language (base + exceptions + max), borders,
   elevation (shadow vs tonal layering), texture/gradient policy (explicit yes-where or
   no).
7. **`## 7. Motion & Feedback`** — animation character, duration/easing bands, interaction
   states (hover/active/focus/disabled — never hue-alone).
8. **`## 8. Component Inflections`** — minimum coverage buttons/inputs/cards/navigation,
   1-3 sentences each on what makes this theme's version distinct; explicitly list
   components left at base defaults.
9. **`## 9. Accessibility Commitments`** — WCAG target (2.2 AA minimum), contrast minimums
   (4.5:1 body / 3:1 large-UI) with near-the-line pairs called out, focus visibility,
   reduced-motion behavior.
10. **`## 10. Facet Mapping Appendix`** — advisory table, treatise section → engine YAML
    facet → seed hints. Written **last**, summarizes decisions already made in §1-9 — if
    writing this table surfaces a new decision, put it in the body first, not here.

**Quality bar — every claim must be decidable, not vague:**

| Reject | Accept |
|---|---|
| "Warm, inviting colors" | "Palette centers on 20-35° hues; neutrals warm-tinted ~4%; no hue cooler than 220° outside semantic info-blue" |
| "Clean, modern typography" | "Single geometric sans (Inter) for all UI text; mono reserved for code/data; no serif anywhere" |
| "Subtle animations" | "Micro-interactions 80-120ms ease-out; nothing exceeds 250ms; no motion on scroll" |
| "Accessible" | "AA minimum; ember-500 on canvas-900 ≈4.7:1 — recheck if canvas lightens" |

Give ranges not adjectives, state exclusions ("never X"), name tradeoff winners when two
goals conflict, anchor to measurables (contrast ratios, hue degrees, ms, px). Target length
150-400 lines per treatise — long enough to decide with, short enough to hold in context.

## 3. Tail step — screen allocation for Stage C

Write `design/asset-prompts/screens/allocation.yaml`. Rank the project's screens (from
`project-management/screens/`) by narrative weight — primary flows first, then dashboard,
storyboard, settings, modal — and distribute across every theme this project now has (new +
existing):

```yaml
version: 1
inventory_total: {N}              # total screens in project-management/screens/, README.md excluded
unique:                           # each screen assigned to exactly ONE theme
  - screen: "03-dashboard"        # matches the screens/{NN}-{slug}.md filename, no extension
    theme: "nocturne"
  - screen: "07-settings"
    theme: "paper"
overlap:                          # 2-5 identity-defining screens, each assigned to exactly TWO themes
  - screen: "01-landing"
    themes: ["nocturne", "paper"]
  - screen: "02-onboarding"
    themes: ["blueprint", "paper"]
```

Rules: unique-set size = `clamp(inventory_total, 30, 40)` — if the project has fewer than 30
screens total, allocate the whole inventory (`unique` count == `inventory_total`, no
screens left unallocated); overlap set is **2-5** screens, each an identity-defining screen
(the ones that most say "this is theme X") assigned to exactly 2 themes so Stage C can render
a direct side-by-side comparison. Deal the rest round-robin, biased by matching a screen's
category to a theme's mood (e.g., a "storyboard" screen suits a narrative-heavy theme). Every
theme should end up with **5-8** screens total (unique assignments count once, overlap
assignments count once per theme listed) — aim for **~35-45 total image slots** across all
themes combined. `unique[].screen` and `overlap[].screen` values must resolve to real files
under `project-management/screens/`.

## 4. Idempotency

If `design/theme/THEMES.md` and some treatises already exist from a prior partial run, don't
regenerate from scratch — read what's there, top up missing treatises, leave correct ones
alone. If `allocation.yaml` already exists and looks valid, don't overwrite it blindly —
re-run `verify.md` §B against it first and only rewrite if it actually fails.

## 5. Verify

Run `templates/verify.md` §B with `PROJECT={project}` set. Paste every `PASS:`/`FAIL:` line
into your report's `verify:` list.

## 6. Update state and commit

Update `docs/pipelines/project-uplift/state/{project}.yaml`:
- `stage_b.status: done` (or `blocked`)
- `stage_b.attempts` incremented
- `stage_b.effective_theme_count` = your computed E
- `stage_b.new_themes_needed` = `ceil(7-E)` you computed
- `stage_b.themes_written` = list of all theme slugs with a treatise now (new + reverse-engineered)
- `stage_b.allocation_yaml: true`
- Seed `stage_c.themes` with one entry per theme slug, `status: pending`, so Stage C spawns
  know the full roster without re-deriving it.

**Commit protocol** (pathspec-only):

```bash
git add <specific paths only — projects/{project}/design/theme/... projects/{project}/design/asset-prompts/screens/allocation.yaml>
REPO_LOCK_SESSION=$(grep -oP 'repo_lock_session:\s*\K\S+' docs/pipelines/project-uplift/state/_pipeline.yaml) \
repo-lock exec --label "uplift {project} B" -- \
  git commit -m "{project}: uplift stage B — {one-line summary}" \
             -m "Co-Authored-By: Loom <loom@therobotlives.com>" \
  -- <same pathspecs> docs/pipelines/project-uplift/state/{project}.yaml
```

Trailer is **Loom only**.

## 7. Report

Reply **ONLY** with the `templates/report-format.md` block.

## 8. Failure handling

If a `verify.md` §B check fails and you can't fix it this pass: set `stage_b.status:
blocked` with a `blocked:` reason in the state file, still commit the state file alone, and
report `status: failed`/`blocked` with `blockers:` populated.
