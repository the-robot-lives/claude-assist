---
skill: trl-theme-designer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-15
---

# Theme Designer — Introduction

Fine-tune styleguide-engine themes from a design-theory **theme treatise** into production
YAML. This skill consumes a treatise (authored upstream by trl-user-experience-engineer),
extracts the ~12 seed values that drive the engine's 4-pass cascade (300+ CSS custom
properties), overrides only the facet files that deviate from the base theme, verifies
light/dark/high-contrast modes against the treatise's accessibility commitments, and
audits drift between the treatise and the YAML. It does NOT author treatises, brand
identity, or style guides from scratch, and it does not implement app frontends or engine
internals.

## Input Contract

```yaml
inputs:
  arguments:
    - name: treatise_path
      type: file-path
      required: true
      description: "The theme treatise to realize or audit against"
      example: "projects/gotta.cc/design/theme/treatise-ember.md"

    - name: theme_dir
      type: file-path
      required: false
      description: "Existing theme-{slug}/ directory to tune; created if absent"
      example: "projects/gotta.cc/design/theme/theme-ember/"

  file_conventions:
    - pattern: "projects/{domain}/design/theme/treatise-{slug}.md"
      format: markdown
      description: >
        Theme treatise — canonical 10 sections: 1 Identity, 2 References & Anchors,
        3 Color Story, 4 Typographic Voice, 5 Space & Density, 6 Shape & Surface,
        7 Motion & Feedback, 8 Component Inflections, 9 Accessibility Commitments,
        10 Facet Mapping Appendix. Lives beside the theme directory it governs.
      schema: "See references/treatise-intake.md for the section-by-section parse"
      example: |
        # Treatise: Ember
        ## 1. Identity
        Warm dark dev-tool theme...
        ## 3. Color Story
        Canvas near-black, single ember-orange accent...

    - pattern: "projects/{domain}/design/theme/theme-{slug}/*.yaml"
      format: yaml
      description: >
        Engine theme facets (~20 files): style-guide.meta.yaml, style-guide.vars.yaml,
        branding.yaml, style-guide.color-modes.yaml, plus optional facets. slug must
        match the directory suffix; base-theme: "theme-style-guide".
      schema: "See references/facet-tuning-guide.md and the engine's docs/reference/yaml-config.md"
      example: |
        # style-guide.meta.yaml
        name: "Ember"
        slug: "ember"
        base-theme: "theme-style-guide"

  context_expectations:
    - "Node 18+ and npm; .npmrc resolving @noizu scope to npm.noizu.com (Verdaccio)"
    - "The canonical base theme (theme-style-guide) is auto-copied by the npx launcher — never hand-authored"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Tuned theme directory"
      path: "projects/{domain}/design/theme/theme-{slug}/"
      format: directory-tree
      description: "Delta-only YAML facets inheriting base-theme: theme-style-guide; clean serve run (no ✗/⚠)"
      example: |
        theme-ember/
          style-guide.meta.yaml
          style-guide.vars.yaml
          branding.yaml
          style-guide.color-modes.yaml

    - name: "Conformance notes"
      path: "projects/{domain}/design/theme/conformance-{slug}.md"
      format: markdown
      description: "Treatise-vs-YAML audit: satisfied commitments, deltas, waived items with rationale"

  side_effects:
    - "Runs `npx @noizu/styleguide serve <theme-dir>` locally for visual verification (dev server)"
    - "The launcher copies theme-style-guide into the config dir on first run (expected, keep it)"

  handoff:
    - skill: trl-react-engineer
      artifact: "Tuned theme directory"
      description: "Project frontend integration (Workflow C: src/config/theme-{slug}/, npm run regen)"
    - skill: trl-user-experience-engineer
      artifact: "Conformance notes"
      description: "When drift requires a treatise revision rather than a YAML change"
```

## Conventions

```yaml
conventions:
  naming:
    - "Theme dirs: theme-{slug}; slug in style-guide.meta.yaml matches the directory suffix"
    - "Variants: theme-{slug}-{variant} (e.g., theme-ember-light) chaining base-theme to the parent"
  structure:
    - "The treatise is the contract — every YAML value traces to a treatise section"
    - "Override only deltas; everything else inherits from theme-style-guide"
    - "Tune seeds (style-guide.vars.yaml) before facet overrides — the cascade does most of the work"
    - "css-snippets, jsx-snippets, scoped-vars, css-load, jsx-load ACCUMULATE with the base; other facets replace"
  anti_patterns:
    - "Never copy or symlink themes into styleguide-engine/app/src/config/ — launchers manage hosting"
    - "Never hand-author theme-style-guide (the base) — it's provided by the launcher/package"
    - "Do not author a treatise or invent brand identity — hand off to trl-user-experience-engineer"
    - "Do not edit engine internals or app frontend code"
  prerequisites:
    - "A treatise exists (or the user accepts working from an existing theme + verbal direction)"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (now) |
| 2 (before executing) | `SKILL.md` | Full workflow, decision tables |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | Running a specific workflow |
| 4 (as needed) | `references/treatise-intake.md` | Parsing the 10 treatise sections |
| 4 (as needed) | `references/seed-extraction.md` | vars.yaml seeds + cascade behavior |
| 4 (as needed) | `references/facet-tuning-guide.md` | Override-vs-inherit per facet |
| 4 (as needed) | `references/verification-and-drift.md` | Mode matrix, drift audit |

## Quick Examples

### New theme from treatise
`/trl-theme-designer realize projects/gotta.cc/design/theme/treatise-ember.md`

### Handoff from upstream
After trl-user-experience-engineer writes `treatise-ember.md`, invoke `/trl-theme-designer` to build `theme-ember/`.
