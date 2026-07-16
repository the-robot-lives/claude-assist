---
skill: trl-skill-engineer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
last_updated: 2026-07-16
---

# Skill Engineer — Introduction

Design, build, and validate AI agent skills from requirements through production-ready
scaffolds. This meta-skill covers the full lifecycle: discovery, archetype selection,
scaffold generation, reference authoring, MCP/CLI tool selection, and quality validation
against a scoring rubric. It targets engineers building Claude Code skills in this repo's
canonical format. Primary value: turning domain knowledge into a self-contained, testable
skill that passes its own quality gate.

## Input Contract

```yaml
inputs:
  arguments:
    - name: skill_intent
      type: freeform
      required: true
      description: "What the skill should do, or which existing skill to evaluate/improve"
      example: "build a skill that debugs failing REST API integrations"

    - name: existing_skill_path
      type: file-path
      required: false
      description: "Path to an existing skills/{name}/ directory to audit or extend"
      example: "skills/api-debugger/"

    - name: brief_file
      type: file-path
      required: false
      description: "A filled skill-brief-worksheet capturing domain, audience, use cases"
      example: "assets/skill-brief-worksheet.md"

    - name: tailoring_flags
      type: flags
      required: false
      description: >
        Opt-in scaffold modes, via env var or stated in-conversation:
        DYNAMIC_SKILLSET_TAILOR=enabled (variant-group scaffolds + .USE-CASE/ overlays),
        NPL_MCP_ENABLED_SKILLS=true (npl-mcp fetch-stub files). Off by default;
        never inferred from repo state.

  file_conventions:
    - pattern: "skills/{skill-name}/"
      format: directory-tree
      description: "The skill module being created or evaluated"
      schema: "See references/scaffold-specification.md for the canonical file tree"

  context_expectations:
    - "Git repository with a skills/ directory following the canonical module structure"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Skill scaffold"
      path: "skills/{skill-name}/"
      format: directory-tree
      description: "INTRODUCTION.md, SKILL.md, references/, assets/, scripts/"
      example: |
        skills/api-debugger/
        ├── INTRODUCTION.md
        ├── SKILL.md
        ├── references/agent-playbook.claude-code.md
        ├── references/worked-example-rest-api.md
        ├── assets/project-tracker.md
        └── scripts/
    - name: "Quality audit"
      path: "(inline or skills/{skill-name}/AUDIT.md)"
      format: markdown
      description: "Scoring-rubric results with per-dimension evidence"
    - name: "Tailored scaffold (flag-gated)"
      path: "skills/{skill-name}/"
      format: directory-tree
      description: >
        With DYNAMIC_SKILLSET_TAILOR: per-file variant groups ({FILE}.md.prompt spec,
        .{FILE}.md/baseline.md + meta, live symlink) and .USE-CASE/{slug} overlays with
        meta.lock. With NPL_MCP_ENABLED_SKILLS: fetch-stub files with local fallbacks.
        See references/dynamic-prompt-tailoring.md and references/npl-mcp-prompt-stubs.md.

  side_effects:
    - "None required — all output is file-based. Slash-command registration is automatic."

  handoff:
    - skill: trl-skill-evaluator
      artifact: "Skill scaffold"
      description: "Run task-flow / exam-based evals against the finished skill"
    - skill: trl-prompt-optimizer
      artifact: "Tailored scaffold (flag-gated)"
      description: "Generate, compress, and eval-score variants for the seeded variant groups"
    - skill: trl-user-experience-engineer
      artifact: "Skill scaffold"
      description: "Design a landing/product page for a published skill"
```

## Conventions

```yaml
conventions:
  naming:
    - "Skill directory and SKILL.md `name` field match exactly (e.g. dir trl-skill-engineer → name: trl-skill-engineer)"
    - "Reference files are kebab-case named after the task they support, not the concept"
  structure:
    - "Every skill has INTRODUCTION.md, SKILL.md, references/, assets/, scripts/"
    - "SKILL.md is the lean entry point; depth lives in references/"
  anti_patterns:
    - "Do not inline full playbooks into SKILL.md — link to references/"
    - "Do not ship reference stubs or placeholder sections"
    - "Do not make cross-references hard dependencies — they are advisory"
  prerequisites:
    - "skills/ directory exists and follows the canonical module structure"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | For the full methodology, archetypes, and phase workflow |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | When running a specific build/audit workflow |
| 4 (as needed) | `references/{specific-file}.md` | Discovery, scaffold spec, patterns, MCP catalog per task |

## Quick Examples

### Build from scratch
`/trl-skill-engineer build a skill for debugging failing REST API integrations`

### Evaluate an existing skill
`/trl-skill-engineer audit skills/api-debugger against the quality checklist`

### Fast path with a brief
Fill `assets/skill-brief-worksheet.md`, then `/trl-skill-engineer scaffold from this brief`
