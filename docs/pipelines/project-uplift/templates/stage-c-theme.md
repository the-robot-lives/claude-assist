# stage-c-theme.md (version: 2)

Stage C — for **one theme** of one project: author render prompts, generate images, read
them back and reflect, implement the theme's engine YAML, validate, write a conformance
note, curate which renders enter git. Runs once per theme (fresh agent per theme, sequential
within a project). Self-contained: this file + your state file + spawn params + committed
repo reference docs.

## Params (from your spawn prompt)

- `project` — the slug under `projects/{project}/`
- `theme` — the **full** theme slug you're working on this run, e.g. `npl-prism` —
  **never** a shortened form like `prism`. This exact string is the `theme-{theme}/`
  dir suffix, the `treatise-{theme}.md` filename, the key under `allocation.yaml`'s
  `unique[].theme` / `overlap[].themes[]`, and the `stage_c.themes.{theme}` state
  key. Every path in this template is built from this one value — copy it as given,
  never strip a prefix or re-derive a shorter form.
- `eval` — `on`/`off` (check `state/_pipeline.yaml` `preflight.eval.status` if not passed —
  it's the authority)
- `media` — `on`/`off` (same — `preflight.media.status`)
- `REPO_LOCK_SESSION` — the repo-lock session id for your §10 commit. Use this value
  exactly as given; do not read or grep `state/_pipeline.yaml` for it — that file is
  off-limits to stage agents (see §10).

## 0. Setup

1. Read `docs/pipelines/project-uplift/state/{project}.yaml` first — `stage_c.themes.{theme}`
   is your slice of state; `stage_b.allocation_yaml` confirms Stage B already ran.
2. Set `stage_c.themes.{theme}.status: in-progress` in the state file now, uncommitted.
3. Do **not** create a tobor session.
4. Invoke **Skill(trl-theme-designer)** before doing the YAML implementation work in §4 — it
   governs seed-vs-facet override discipline and the mode-verification matrix.
5. Read `design/theme/treatise-{theme}.md` (Stage B wrote it, `status: sketch`) and
   `design/asset-prompts/screens/allocation.yaml` to get this theme's screen slice.

**Scope boundary — read this before touching any files:** you write to
`projects/{project}/design/theme/theme-{theme}/`, `design/theme/treatise-{theme}.md`,
`design/theme/conformance-{theme}.md`, and `design/asset-prompts/screens/{theme}/`. You do
**not** touch anything under `app/frontend/src/config/`, `web/src/config/`, or any other
frontend-integration path even if one already exists for this project — wiring the tuned
theme into the actual frontend build (`npm run regen`, the `/styleguide` route) is
out of scope for this pipeline, owned by a future trl-react-engineer pass. If you see an
existing `app/frontend/src/config/theme-style-guide/` in this project, that's the **base**
theme scaffold (its own `style-guide.meta.yaml` literally says "Override this in your
project's theme-{slug}/ directory") — useful only as a reference for the full field shapes a
theme directory can contain; do not copy it wholesale or edit it.

## 1. Author render prompts

For each screen in this theme's allocation slice (from `allocation.yaml` — both `unique`
entries where `theme == {theme}` and `overlap` entries where `{theme}` is in `themes`),
write `design/asset-prompts/screens/{theme}/{NN}-{screen-slug}.media.prompt`, modeled
exactly on `projects/NoizuPromptLingo/design/asset-prompts/chat-ux-v2-room.media.prompt`:

```yaml
schema: "0.4"
id: {theme}-{NN}-{screen-slug}
type: image
quality: high

# {one-liner: what this product/app is} — {screen name} screen.
# Theme tenets: {2-3 short tenets pulled from the treatise, e.g. "warm dark, single ember accent, 4px radius"}.
# Palette: {2-4 key hex values from this theme's seeds}.

prompt:
  system: |
    You are a senior product designer rendering a high-fidelity UI mockup of
    {one or two sentences setting the product register — calm/dense/playful/etc,
    matching treatise §1 Perception and §4 Typographic Voice}.
  text: |
    A 16:9 high-fidelity UI mockup of the {screen name} screen of {product name}.

    OVERALL LAYOUT ({N} bands): {describe the major regions — nav, content, sidebar, etc.}

    {Section-by-section breakdown of what's visible, in the same density and specificity
    as the NoizuPromptLingo example — name real UI elements (nav rail, header band,
    composer, etc.), not vague gestures. Pull directly from the screen's
    project-management/screens/{NN}-{screen-slug}.md "Key Components" + "Description".}

    PALETTE & TYPE: {treatise §3 palette narrative + §4 type — name colors
    descriptively in prose (never a literal hex/hue code — see the no-hex warning
    below), the neutral temperature, the font character.}

    SHAPE & SURFACE: {treatise §6 — radius language, elevation, border/texture policy.}

    MOOD: {treatise §1 Perception, restated as a rendering instruction.}
  negative: "watermark, signature, lorem ipsum placeholder text, low-fidelity wireframe, monitor/device photograph framing, blurry, distorted UI"

output:
  formats:
    - format: png
  dimensions:
    width: 1920
    height: 1080
    aspect_ratio: "16:9"

eval:
  pass_threshold: 0.72
  criteria:
    relevance: {weight: 3, description: "Matches the screen's actual layout and key components as specified"}
    theme_fidelity: {weight: 3, description: "Palette, typography, radius/shape language match the treatise, not generic UI defaults"}
    composition: {weight: 2, description: "Clear visual hierarchy, plausible real-product layout"}
    technical: {weight: 2, description: "Sharp, correct 16:9 aspect, no artifacts"}
  reject_if:
    - "lorem ipsum or placeholder text visible"
    - "watermark or signature visible"
    - "wireframe-level fidelity instead of high-fidelity mockup"

tags: [{theme}, {project}, screen-mockup]
```

`prompt.text` must be **≤4000 characters** — subject-first prose, not a bullet dump; write it
the way the NoizuPromptLingo example does (flowing paragraphs with named UI regions in caps
for scanability). Keep the `eval:` block even though today's render run skips evaluation
(see §2) — it's a durable part of the file for whenever the evaluator is back online.

**No hex in `prompt.text`:** a literal hex code written into `prompt.text` gets
rendered as literal on-screen UI text by the image model (e.g. a stray `#f7f8ff` in
the prompt showed up painted onto the mockup as fake UI copy). Precise hex is fine
in the `# Palette:` YAML **comment** above — comments aren't transmitted to the
model — but everywhere inside `prompt.text` (including PALETTE & TYPE), describe
colors by name in prose ("cool violet-white", "deep ink", "warm ember"), never by
hex/hue code.

## 2. Render

Render **one file at a time** (never batch `-r`/`-j` — those are interactive-selection modes
and will hang a non-interactive agent):

```bash
generate-media-prompt --no-eval -n 1 design/asset-prompts/screens/{theme}/{NN}-{screen-slug}.media.prompt
```

Drop `--no-eval` only if `state/_pipeline.yaml` `preflight.eval.status: on` at the time you
run this (check it fresh — don't assume today's `off` from setup is still true later).
Identity-defining **hero screens** (the ones in `allocation.yaml`'s `overlap` list) get
`-n 2` instead of `-n 1` so you have a choice. **Hard cap: 12 API calls for this theme** —
budget accordingly (a ~7-screen theme with 1-2 hero screens fits comfortably; if your slice
is larger, prioritize hero + highest-narrative-weight screens and note in your report which
screens were skipped for budget).

If `media: off`: skip rendering entirely, leave `.media.prompt` files as the deliverable, and
mark this theme's images `deferred` in state (see §7) — this is a first-class, expected
outcome, not a failure.

## 3. Read, reflect, amend the treatise

For each generated PNG, `Read` it (multimodal). Compare what you see against the treatise's
**§3 Color Story, §4 Typographic Voice, §6 Shape & Surface, §8 Component Inflections** — does
the render actually match what the treatise commits to? Two directions of correction:
- Render drifted from a good treatise → note it, consider a re-render if budget allows, or
  accept and note the gap.
- Render revealed the treatise was underspecified or wrong (e.g., you said "soft shadows"
  but the only way to get a coherent premium look was flatter elevation) → **amend the
  treatise in place**: bump its `revision:` field, keep `status: sketch` until all screens
  are reviewed, then flip to `status: full` once this pass is done for every screen in your
  slice.

## 4. Implement the theme YAML — deltas only

Build `design/theme/theme-{theme}/`. Everything inherits from `base-theme:
"theme-style-guide"` unless the treatise demands a deviation — **never hand-author the base**,
only the deltas. Seeds before facets: a one-line seed change usually outperforms many facet
overrides.

**`style-guide.meta.yaml`** — always required:
```yaml
name: "{Theme Display Name}"
slug: "{theme}"
title: "{Display Title}"
description: "{one-line tagline from treatise §1 Intent}"
base-theme: "theme-style-guide"
```

**`style-guide.vars.yaml`** — the ~12 canonical seeds, only the ones this theme's treatise
actually pins (leave the rest to the base cascade):

| Seed | Pull from treatise | Touch when… |
|---|---|---|
| `white` | §3 lightest surface | canvas isn't pure white |
| `black` | §3 darkest value | dark canvas is tinted, not default `#000` |
| `brand-red`/primary accent | §3 primary accent | always — this is the theme's voice |
| secondary/tertiary accent | §3 | treatise names a 2nd/3rd accent |
| `success`/`warning`/`error`/`info` | §9 + §3 | default clashes with palette temperature or fails contrast |
| `font-sans` | §4 | always — must match `branding.yaml` `font-url` |
| `font-mono` | §4 | treatise names a mono voice |
| `radius` | §6 | always — cheapest strong signal (0-2px stern, 6-8px friendly, 12px+ soft) |

**Seed trap:** the base's accent seeds are named `brand-red` / `brand-blue` /
`brand-yellow` — **not** bare `red`/`blue`/`yellow` keys (the base doesn't wire
those as accent-driving keys; overriding them is a silent no-op). Overriding
`brand-red` alone is also **not enough**: the base pins `brand-red-light` (and
`brand-blue-light` / `brand-yellow-light`) to a `color-mix(...)` expression with the
*old* hex hard-coded inside it — e.g. `color-mix(in srgb, #e20613 70%,
var(--surface))` — **not** `var(--brand-red)`. If you override `brand-red`, also
re-point its `-light` sibling to read the override, or the tint silently stays the
old brand color while the base accent changes:
```yaml
brand-red: "#{new-hex}"
brand-red-light: "color-mix(in srgb, var(--brand-red) 70%, var(--surface))"
```
(same pattern for `brand-blue`/`brand-blue-light` and `brand-yellow`/`brand-yellow-light`.)

**`branding.yaml`** — always required, mirrors treatise §1 verbatim. Every shipped
sibling theme includes **`logo-text` and `font-url`** — don't drop them even though
the skeleton below only shows the minimum shape; `font-sans` in
`style-guide.vars.yaml` must name the same font family `font-url` loads:
```yaml
name: "{Theme Display Name}"
logo-text: "{short mark/wordmark, e.g. project initials}"
font-url: "{Google Fonts (or equivalent) stylesheet URL for font-sans + font-mono}"
intent: "{treatise §1 Intent}"
perception: "{treatise §1 Perception}"
audience: "{treatise §1 Audience}"
tone: "{treatise §1 Tone}"
keywords: [{treatise §1 Keywords, 4-6}]
```

**`style-guide.color-modes.yaml`** — always required, real light AND dark maps (not just one):
```yaml
color-modes:
  light: {surface: "...", text: "...", ...}
  dark: {surface: "...", text: "...", ...}
```

**Project-specific sample elements** (per the plan's "project-specific sample sections"
requirement) — give this theme entries that speak to *this product's actual UI
patterns*, not the generic base-theme boilerplate ("Visual Foundation / Typography /
Color Palette" placeholders). E.g. if the product has a distinctive domain object (a
fight card, a chat room, a dashboard widget), give it a themed treatment.

**Wholesale-replace trap:** `style-guide.typography.yaml`,
`style-guide.design-sections.yaml`, and `style-guide.page-sections.yaml` each
**replace the base file wholesale** the moment a theme provides one — unlike
`css-snippets`/`jsx-snippets`/`scoped-vars`/`css-load`/`jsx-load`, which
**accumulate** on top of the base. A minimal `style-guide.design-sections.yaml`
meant to *add* one project-specific section will instead **delete every inherited
base section**. Default to the safe, accumulating path: add project-specific sample
elements via `style-guide.css-snippets.yaml`, self-scoped to this theme
(`html[data-design-theme="{theme}"] ...`), instead of touching
`design-sections`/`page-sections`/`typography`. If a treatise genuinely requires
overriding one of those three files (not just adding to it), you must re-declare the
**full base set plus your additions** in that file — never a diff-sized partial.
This polish is optional-but-expected, not a hard gate; the trap only bites once you
touch these three specific files.

Beyond these four-plus-two, add delta facets **only** where the treatise demands a deviation
the seed cascade can't produce (see trl-theme-designer's facet override decision table,
loaded via the Skill invocation in §0) — most themes won't need more than
`style-guide.css-snippets.yaml` for a couple of component inflections (§8) and maybe
`style-guide.typography.yaml` for a non-default type scale.

## 5. Validate

Check `state/_pipeline.yaml` `preflight.styleguide_serve.status` first.

**If `on`:**
```bash
timeout 45 npx @noizu/styleguide serve projects/{project}/design/theme > /tmp/serve-{theme}.log 2>&1
grep "✗" /tmp/serve-{theme}.log   # must be empty; any ⚠ must be explained in your conformance note
```

**If `off` (current default — public npm 404s on `@noizu/styleguide`, no private registry
configured):** use the legacy in-repo generator, pointed at your theme directory via env var
override (it does not take a directory as a CLI argument):
```bash
cd components/styleguide/app && \
STYLEGUIDE_CONFIG_ROOT="$(git rev-parse --show-toplevel)/projects/{project}/design/theme" \
STYLEGUIDE_OUTPUT="/tmp/design-system.generated.{theme}.css" \
npm run generate-css > /tmp/generate-css-{theme}.log 2>&1
cd - > /dev/null
grep -iE "error|exception" /tmp/generate-css-{theme}.log   # must be empty
```
Note in your conformance note which path you used — the legacy path doesn't have the
`✗`/`⚠` severity distinction the npx serve command gives you, only pass/fail on
error/exception.

**Color-modes validation gap on the legacy path:** the legacy `generate-css`
fallback does **not** emit `style-guide.color-modes.yaml`'s literal light/dark maps
into the generated output (verified across themes) — only the white/black seed
cascade resolves modes on this path. An authored `color-modes` dark map is therefore
**unverifiable** while `styleguide_serve.status: off`: you can confirm the
seed-cascade fallback looks reasonable, not that your literal light/dark maps took
effect. Full color-modes verification requires the (currently unavailable) `npx
@noizu/styleguide serve` path — record this limitation explicitly in the
conformance note rather than asserting dark-mode conformance you couldn't actually
verify.

Then run the mode-verification matrix from trl-theme-designer (loaded via §0's Skill
invocation) — light/dark contrast per treatise §9, focus visibility, mode distinctness —
and fix anything failing before moving on.

## 6. Conformance note

Write `design/theme/conformance-{theme}.md` from
`skills/trl-theme-designer/assets/theme-conformance-report.md` (read that template — it has
a Value Trace table, Claim Coverage table, Mode-Verification Matrix Results, Contrast
Measurements, Deviations & Waivers, Standing Cautions, Escalations, and Session History
sections). Fill it honestly — a `DRIFTED (remediation pending)` verdict with real reasoning
is more useful than a false `CONFORMANT`.

## 7. PNG curation

Classify each render: **impactful** (genuinely represents the theme well, worth showing the
user in the pilot digest or keeping as the canonical reference for this screen) vs
**low-value** (rejected candidate, redundant hero-screen `-n 2` variant that lost, or just
weak). `.genai.*/` variant directories and bare `*.png` files are gitignored by design (the
user tracks the full render corpus separately) — impactful finals need an explicit force-add:

```bash
git add -f design/asset-prompts/screens/{theme}/{NN}-{screen-slug}.png   # impactful only
```

Leave low-value PNGs untracked on disk (don't delete them — the user wants the full corpus
available locally even if git doesn't track it). **Never delete any `.genai.*/` directory**
— those hold every candidate variant + metadata, and are the raw material for the user's
future separate tracking repo.

## 8. Idempotency

If this theme's `.media.prompt` files, PNGs, or theme YAML already exist from a prior partial
run, don't regenerate from scratch — top up what's missing (e.g., a screen with a prompt file
but no PNG because a previous run hit the API-call cap), re-validate, and only touch what's
actually incomplete or wrong.

## 9. Verify

Run `templates/verify.md` §C with `PROJECT={project}` and `THEME={theme}` set. Paste every
`PASS:`/`FAIL:` line into your report's `verify:` list.

## 10. Update state and commit

Update `docs/pipelines/project-uplift/state/{project}.yaml`'s `stage_c.themes.{theme}`:
`status: done` (or `blocked`), `prompts`, `images`, `api_calls` (must be ≤12), `avg_eval`
(null if eval was off), `yaml: true`, `conformance: true`.

**Commit protocol** (pathspec-only, one commit for this theme):

```bash
git add <specific paths — design/theme/treatise-{theme}.md design/theme/theme-{theme}/... design/theme/conformance-{theme}.md design/asset-prompts/screens/{theme}/*.media.prompt> \
        <and -f any impactful PNGs individually, per §7>
REPO_LOCK_SESSION={value from your spawn params, §0} \
repo-lock exec --label "uplift {project} C:{theme}" -- \
  git commit -m "{project}: uplift stage C ({theme}) — {one-line summary}" \
             -m "Co-Authored-By: Loom <loom@therobotlives.com>" \
  -- <same pathspecs> docs/pipelines/project-uplift/state/{project}.yaml
```

Trailer is **Loom only**. `REPO_LOCK_SESSION` above is the value handed to you as a
spawn param (§0) — never `grep` or read `state/_pipeline.yaml` to obtain it; that
file is off-limits to stage agents.

## 11. Report

Reply **ONLY** with the `templates/report-format.md` block. `theme:` is required in this
stage's report.

## 12. Failure handling

If a `verify.md` §C check fails and you can't fix it this pass (including hitting the
12-call cap before finishing renders): set `stage_c.themes.{theme}.status: blocked` with a
`blocked:` reason, still commit the state file (and any completed prompts/YAML) alone, and
report `status: failed`/`blocked` with `blockers:` populated.
