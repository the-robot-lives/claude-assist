---
id: US-020
title: "Save and instantiate an agent template"
slug: save-and-instantiate-an-agent-template
personas: [P-002, P-003]
epic: "Agents & Cognition"
priority: should-have
complexity: medium
tags: [templates, agent-creation, reuse]
---

# US-020: Save and Instantiate an Agent Template

## User Story

**As a** agent designer/prompt engineer
**I want to** save a well-tuned agent's purpose/identity/self-image/profile prompts as a reusable template and instantiate new agents from it
**So that** I don't have to hand-recreate a proven persona every time I need a similar agent in a new project

## Acceptance Criteria

- **Given** I have an agent whose current prompt versions I consider a good baseline
  **When** I save it as a template with a name and description
  **Then** the template captures a snapshot of the current versions of each prompt field, independent of future edits to the source agent

- **Given** a saved template exists in my template library
  **When** I instantiate a new agent from it and supply a new handle/name
  **Then** the new agent is created with prompt fields seeded from the template's snapshot as its version 1 content

- **Given** I browse the template library
  **When** I filter or search by tag or name
  **Then** I see templates I authored as well as any templates shared with my team (see next criterion)

- **Given** a team lead wants a template usable by the whole team
  **When** I mark a template as shared at the org or project level
  **Then** other members of that scope can see and instantiate it, but cannot edit the original template unless granted edit rights

## Notes
Templates are snapshots, not live links — editing the source agent afterward does not retroactively change the template. Sharing scope (personal/team/org) matters for P-003 building out a standard agent bench across a team.
