---
skill: trl-prompt-optimizer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-16
---

# Prompt Optimizer — Introduction

Prompt Optimizer compresses an existing prompt to its minimum viable size with measured, declared loss, and restyles it into equivalent-behavior methodologies when the format itself is the compression axis. It is for anyone holding a prompt that is too big, too expensive, or the wrong shape — a CLAUDE.md, a system prompt, an agent definition, a slash command, a `.prompt` spec. Its distinguishing value is discipline: every dropped byte is ledgered, and every candidate is scored against an eval corpus before it is promoted. It manages the full lifecycle (source → variants → evals → best-version selection) in a file-mode convention and an MCP-store spec.

## Input Contract

```yaml
inputs:
  arguments:
    - name: source_prompt
      type: file-path
      required: true
      description: "The prompt to optimize (any text prompt: CLAUDE.md, system prompt, agent md, .prompt)."
      example: "CLAUDE.md"
    - name: compactness
      type: choice            # 0 | 1 | 2 | 3 | 4 | 5
      required: false
      description: "Target level on the compactness scale (0 verbatim … 5 telegraphic-lossy)."
      example: "4"
    - name: token_budget
      type: string            # integer token ceiling
      required: false
      description: "Hard ceiling; overrides compactness when they conflict. Skill picks the mix that fits."
      example: "1200"
    - name: style
      type: choice
      required: false
      description: "pure-npl | yaml-meta | mermaid | checklist | pointer-index | shorthand | plain"
      example: "pointer-index"
    - name: protect
      type: freeform
      required: false
      description: "Facts/areas that must survive verbatim (behavioral rules, gotchas, exact commands)."
      example: "the tofu/terragrunt port-forward gotcha; all secret commands"
    - name: lossy_ok
      type: freeform
      required: false
      description: "Areas where loss is acceptable — spend savings here first."
      example: "the repository-overview prose"

  file_conventions:
    - pattern: "{name}.md.prompt"
      format: yaml
      description: "Prompt spec: original body, key_requirements, eval rules + dataset, compactness/style axes, pin. Extends media payload schema v0.4 with type: prompt."
      schema: "assets/prompt-spec-template.md.prompt (extends skills/shared/asset-prompt-payload-schema.md)"
      example: |
        schema: "0.4"
        id: claude-md-root
        type: prompt
        key_requirements: ["session registration survives", "secret commands verbatim"]
        eval: { rules: "Score compliance, fact recall, token cost.", dataset: [...] }
    - pattern: ".{name}.md/{slug}.md + .{name}.md/{slug}.meta.md"
      format: markdown
      description: "Variants dir: one file per variant + a meta file with compression notes and eval scores."
      schema: "assets/variant-meta-template.md"

  context_expectations:
    - "The source prompt exists and is readable."
    - "For NPL reference-mode: NPLLoad/NPLSpec MCP tools OR projects/NoizuPromptLingo/ present (NEVER inferred from $NPL_PROJECT/$NPL_ORG — those are tobor session slugs)."
    - "For eval scoring: a dataset in the .prompt spec, or the caller supplies adhoc cases."
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Optimized prompt variant(s)"
      path: ".{name}.md/{slug}.md"
      format: markdown
      description: "One or more compressed/restyled variants of the source prompt."
    - name: "Variant meta / loss ledger"
      path: ".{name}.md/{slug}.meta.md"
      format: markdown
      description: "How it was compressed, what was dropped (what/why/recoverable-where), eval scores."
    - name: "Best-version symlink"
      path: "{name}.md -> .{name}.md/{slug}.md"
      format: custom
      description: "Points at the best-eval variant (or the pinned one). Atomic to repoint."
    - name: "Prompt spec"
      path: "{name}.md.prompt"
      format: yaml
      description: "Spec file: original, key_requirements, eval rules + dataset, axes, pin."

  side_effects:
    - "Creates/repoints a symlink at {name}.md; the original body is retained forever as the baseline variant."
    - "No external calls unless NPL reference-mode is used (NPLLoad MCP) or an eval model is invoked."

  handoff:
    - skill: content-media-engine
      artifact: "Prompt spec"
      description: "Media tool reads a type: prompt .prompt to generate/refresh variants (see file-mode-convention.md appendix)."
    - skill: trl-skill-engineer
      artifact: "Optimized prompt variant"
      description: "A compressed SKILL.md/command body dropped back into its skill."
```

## Conventions

```yaml
conventions:
  naming:
    - "Spec file: {name}.md.prompt. Variants dir: .{name}.md/ (hidden, sibling to the file)."
    - "Variant files: {slug}.md; meta files: {slug}.meta.md. Slugs are kebab-case, encode style/compactness (e.g. pointer-index-c4)."
  structure:
    - "The symlink default target is the best eval score; a pin in the .prompt spec overrides it."
    - "Behavioral rules stay inline; reference material is denoted + pointed at (verified before citing); every variant carries a loss ledger (what dropped, why, recoverable-where)."
  anti_patterns:
    - "Do not compress the reasoning chain or protected rules to hit a budget — report the overage instead."
    - "Do not delete facts when you can move them (prefer level 4 lossless-by-reference over level 5 lossy)."
    - "Do not promote a variant on aesthetics — promote on eval score."
    - "Do not detect NPL via $NPL_PROJECT/$NPL_ORG; those are tobor session slugs, not an install signal."
    - "Do not overwrite the baseline; it is a permanent variant."
  prerequisites:
    - "A readable source prompt. Optionally a .prompt spec with an eval dataset for scored promotion."
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | For the compactness scale, request axes, workflow phases |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | When running a specific workflow |
| 4 (compressing) | `references/compression-methods.md` | For in-LLM method cards + loss accounting |
| 5 (restyling) | `references/style-transforms.md` | When the format is the compression axis |
| 6 (file/MCP lifecycle) | `references/file-mode-convention.md`, `references/mcp-prompt-entries.md` | When persisting variants or serving them |
| 7 (scoring) | `references/eval-and-scoring.md` | When writing rubrics/datasets or pinning |

## Quick Examples

### Compress to a budget
`/trl-prompt-optimizer compress CLAUDE.md to 1200 tokens, protect all secret commands`

### Build a scored variant corpus
Place `CLAUDE.md.prompt` (from `assets/prompt-spec-template.md.prompt`), then `/trl-prompt-optimizer build variants`

### Restyle
`/trl-prompt-optimizer restyle .claude/commands/deploy.md as a mermaid graph`
