---
skill: trl-story-to-release
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-15
---

# Story to Release — Introduction

Takes user stories from backlog to shipped release, implemented faithfully to the personas
they serve and the project's style guide: grooming, constraint binding, planning,
persona-checkpointed implementation, per-persona verification, and audience-targeted release
notes with a rollout strategy. For engineers and agents working in projects that maintain
`project-management/` artifacts (personas, user stories, screens).

## Input Contract

```yaml
inputs:
  arguments:
    - name: story
      type: freeform
      required: true
      description: "Story ID(s) or a description of the story/feature to ship"
      example: "US-042"
    - name: scope
      type: choice
      required: false
      description: "Phase subset: groom | plan | implement | verify | release | full (default full)"
      example: "groom"

  file_conventions:
    - pattern: "project-management/user-stories/US-{NNN}-{slug}.md"
      format: markdown
      description: "User story with frontmatter (id, personas, priority, complexity) and Given/When/Then criteria"
      schema: "Frontmatter + '## User Story' + '## Acceptance Criteria' sections (see generate-personas-and-stories convention)"
      example: |
        ---
        id: US-042
        personas: [P-003]
        ---
        ## Acceptance Criteria
        - [ ] Given a logged-in admin, when they open /dashboard, then key metrics render
    - pattern: "project-management/user-stories/index.yaml"
      format: yaml
      description: "Story index grouped by epic (id, title, personas, priority, complexity, file)"
      schema: "epics: [...] / stories: [...] lists"
    - pattern: "project-management/personas/P-{NNN}-{slug}.md"
      format: markdown
      description: "Persona: demographics, goals, frustrations, technical level, job-to-be-done, scenarios"
      schema: "Frontmatter (id, name, archetype, segment) + section template"
    - pattern: "project-management/personas/index.yaml"
      format: yaml
      description: "Persona index (id, name, archetype, segment, file)"
    - pattern: "project-management/screens/{NN}-{screen-slug}.md"
      format: markdown
      description: "Screen inventory entry: type, category, mapped user stories, key components, navigation"
    - pattern: "design/theme/**/style-guide.*.yaml | design/**/style-guide*.md | docs/style-guide*"
      format: yaml
      description: "Project style guide / design system tokens (styleguide-engine YAML or markdown style guide)"
      schema: "Any of: engine YAML (meta/vars/branding/color-modes), markdown style guide, design tokens"

  context_expectations:
    - "Git repository for the target project"
    - "project-management/user-stories/ exists with at least the target story"
    - "Personas referenced by the story exist under project-management/personas/"
    - "A style guide exists somewhere discoverable (design/, docs/, frontend config); if absent, the skill records that constraint binding ran degraded"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Groomed story + readiness verdict"
      path: "project-management/releases/{story-id}/grooming.md"
      format: markdown
      description: "Ambiguity log, split decisions, readiness gate result"
    - name: "Constraint checklist"
      path: "project-management/releases/{story-id}/constraints.md"
      format: markdown
      description: "Style-guide + persona expectations as checkable implementation constraints (from assets/constraint-checklist-template.md)"
    - name: "Implementation plan"
      path: "project-management/releases/{story-id}/plan.md"
      format: markdown
      description: "Screens/components/APIs touched, task sequence, reuse map"
    - name: "Conformance report"
      path: "project-management/releases/{story-id}/conformance.md"
      format: markdown
      description: "Persona x acceptance-criteria verification matrix + style-guide audit (from assets/conformance-report-template.md)"
    - name: "Release notes + rollout plan"
      path: "project-management/releases/{story-id}/release-notes.md"
      format: markdown
      description: "Per-audience release notes, changelog entry, flag/rollout strategy, post-release validation checks"

  side_effects:
    - "Code changes in the project implementing the story (commits only when the user asks)"
    - "May tick acceptance-criteria checkboxes in the source story file after verification"

  handoff:
    - skill: trl-marketing
      artifact: "Release notes"
      description: "Launch/marketing content for the shipped release"
    - skill: trl-technical-writer
      artifact: "Release notes + changelog"
      description: "Polish user-facing docs and changelog entries"
```

## Conventions

```yaml
conventions:
  naming:
    - "Release artifacts live under project-management/releases/{story-id}/ in kebab-case"
    - "Story/persona IDs are always cited verbatim (US-NNN, P-NNN)"
  structure:
    - "One story (or one coherent split set) per invocation"
    - "Constraint checklist is written BEFORE implementation and is immutable during it — deviations are logged, not silently absorbed"
    - "Every acceptance criterion is verified once per linked persona, not once overall"
  anti_patterns:
    - "Do NOT generate personas, user stories, or screens — that is trl-user-experience-engineer / the project's generator commands"
    - "Do NOT author or modify the style guide — it is a read-only constraint source"
    - "Do NOT write PRDs or launch marketing content"
    - "Do not mark a criterion passed because the code compiles — walk the flow as the persona"
  prerequisites:
    - "Target story exists and passes (or is brought to pass) the story-readiness gate"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you are reading it now) |
| 2 (before executing) | `SKILL.md` | Full 6-phase workflow, gates, and matrices |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | Running groom / bind / implement / verify-release workflows |
| 4 (as needed) | `references/{phase-file}.md` | Deep dive on the phase you are in |

## Quick Examples

### Ship one story end-to-end
`/trl-story-to-release ship US-042` (groom-only: `/trl-story-to-release groom US-017`)

### Handoff from upstream
After `trl-user-experience-engineer` populates `project-management/`, invoke `/trl-story-to-release ship US-001`.
