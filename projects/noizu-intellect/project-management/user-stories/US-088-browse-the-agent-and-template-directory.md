---
id: US-088
title: "Browse the agent and template directory"
slug: browse-the-agent-and-template-directory
personas: [P-002, P-001]
epic: "Search & Discovery"
priority: should-have
complexity: medium
tags: [discoverability, agent-directory, templates]
---

# US-088: Browse the Agent and Template Directory

## User Story

**As an** agent designer (Mara Lindqvist)
**I want to** browse a directory of all agents and agent templates I have access to, with filters for purpose, model, and project
**So that** I can find an existing agent or template to reuse or fork instead of authoring a new one from scratch

## Acceptance Criteria

- **Given** the agent directory view
  **When** it loads
  **Then** it lists every agent and agent template visible to the user, showing handle, name, purpose summary, current prompt version, and assigned project(s)

- **Given** the directory list
  **When** I filter by purpose tag, model, or project
  **Then** the list narrows accordingly, and filters combine with AND semantics

- **Given** an agent template (a reusable starting definition not yet instantiated as a live agent)
  **When** I select it from the directory
  **Then** I can preview its identity/profile prompt and choose to instantiate a new agent from it, pre-filled with the template's versioned content

- **Given** an agent that is deprecated or archived
  **When** browsing the directory
  **Then** it is visually distinguished and excluded from the default view unless an "include archived" toggle is enabled

## Notes
Complements agent creation ([[US-011]]) by giving a starting point beyond a blank definition. Directory browsing is distinct from the memory-topic search in [[US-087]] — this is structural/metadata browsing, not content search, though the two views should cross-link.
