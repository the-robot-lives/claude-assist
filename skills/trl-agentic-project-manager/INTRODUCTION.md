---
skill: trl-agentic-project-manager
version: "1.0"
compatible_with:
  - claude-code
  - codex
  - grok
last_updated: 2026-07-16
---

# Agentic Project Manager — Introduction

Plans multi-agent software delivery as parallelized work DAGs (sequence and fan-out, never timelines) and coordinates execution across heterogeneous providers and harnesses through tobor-* MCP objects. For orchestrator agents and humans who need to split a feature across a fleet of AI workers: it produces the work plan, file-ownership partition, fleet roster, and live tobor coordination bus (session, story, tickets, chat room), then runs the coordinator loop through staged integration gates. Its flagship move is interface-first fan-out — freeze contracts (API spec, UX spec, Cypress `data-cy` selector schema, data model), then write frontend, backend, and test coverage simultaneously.

## Input Contract

```yaml
inputs:
  arguments:
    - name: feature-or-goal
      type: freeform
      required: true
      description: "The feature, story, or initiative to plan and/or coordinate"
      example: "add notification preferences to user settings, full stack"
    - name: mode
      type: choice
      required: false
      description: "plan | staff | coordinate | audit (default: plan, then offer next mode)"
      example: "audit"

  file_conventions:
    - pattern: "project-management/user-stories/*.md"
      format: markdown
      description: "Optional upstream stories/PRDs consumed at intake"
      schema: "As produced by trl-user-experience-engineer / npl-prd-editor"
      example: |
        # Story: Notification preferences
        As a user I want to control which emails I receive...
    - pattern: "project-management/work-plans/{slug}.md"
      format: markdown
      description: "Existing work plan (required for mode: audit or coordinate)"
      schema: "assets/work-plan-template.md"
      example: |
        ## Tracks
        | T1 | frontend | components/preferences/** |

  context_expectations:
    - "tobor-* MCP servers reachable (tobor-root / tobor-sessions) for coordination modes"
    - "$NPL_ORG / $NPL_PROJECT resolvable when creating tobor objects"
    - "Git repository (worktree/staging isolation strategies assume git)"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Work plan"
      path: "project-management/work-plans/{slug}.md"
      format: markdown
      description: "Work DAG, tracks, contracts, file-ownership map, gates"
      example: |
        ## Phase 0 — Contracts
        - C1 API spec (owner: coordinator)
        ## Tracks
        | T1 | frontend | claude-code/deepseek | components/preferences/** |
    - name: "Fleet roster"
      path: "project-management/work-plans/{slug}.roster.md"
      format: markdown
      description: "Agent/provider/harness/persona assignments per track"
    - name: "Coordination bus"
      path: "(tobor MCP objects — no local file)"
      format: custom
      description: "Session + story + one ticket per work unit + chat room with pinned charter"

  side_effects:
    - "Creates a tobor session (live surface today); story/ticket/room objects once the tobor surface exposes them — until then their state runs over repo files (see references/tobor-mcp-integration.md)"
    - "Posts charter and status messages to the coordination room (tobor room when available; append-only room file otherwise)"
    - "No git commits — plans are files; committing is the user's call"

  handoff:
    - skill: trl-story-to-release
      artifact: "Individual tickets"
      description: "Each track's work units execute as story-to-release runs"
    - skill: trl-ui-test-engineer
      artifact: "Selector-schema contract (C-series)"
      description: "Owns data-cy schema discipline for the e2e track"
    - skill: trl-agent-architect
      artifact: "Fleet roster gaps"
      description: "Design missing specialist agents/personas"
```

## Conventions

```yaml
conventions:
  naming:
    - "Work units: U{n}; contracts: C{n}; tracks: T{n}; gates: G{n} — stable IDs referenced in tickets and room messages"
    - "Files use kebab-case; plan slug matches the story/feature slug"
  structure:
    - "One owner per file glob — the ownership map is total (every touched path maps to exactly one track, or to contract/integration)"
    - "Contracts are frozen at the end of Phase 0; changes only via CONTRACT-RFC room messages arbitrated by the coordinator"
    - "Room messages use typed prefixes: CLAIM / STATUS / BLOCKED / HANDOFF / CONTRACT-RFC / DONE"
  anti_patterns:
    - "Never schedule by dates or estimates — blocking edges only"
    - "Never let two tracks share a file; contested files become contract or integration work"
    - "Never coordinate through one harness's session memory — durable state lives in tobor objects"
    - "Never assign contract design to fast/cheap models, or mechanical passes to frontier models"
  prerequisites:
    - "For coordination modes: register/resolve the tobor session before creating child objects"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (now) |
| 2 (before executing) | `SKILL.md` | Full model: DAG concepts, fan-out, workflow phases |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | Running a specific workflow |
| 4 (planning) | `references/parallelization-planning.md`, `references/interface-first-patterns.md` | Building the DAG and applying fan-out |
| 5 (staffing) | `references/provider-strengths.md`, `references/persona-assignment.md` | Assigning tracks |
| 6 (coordination) | `references/tobor-mcp-integration.md`, `references/harness-coordination.md` | Standing up and running the bus |
| 7 (as needed) | `references/merge-conflict-avoidance.md` | Partitioning ownership; integration gates |

## Quick Examples

### Plan only
`/trl-agentic-project-manager plan the parallelization of the checkout redesign story`

### Plan → staff → coordinate
`/trl-agentic-project-manager take user-stories/notification-preferences.md from plan to a live coordination room`

### Audit
`/trl-agentic-project-manager audit project-management/work-plans/checkout-redesign.md for hidden serialization`
