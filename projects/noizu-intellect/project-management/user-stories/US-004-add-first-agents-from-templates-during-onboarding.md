---
id: US-004
title: "Add first agents from templates during onboarding"
slug: add-first-agents-from-templates-during-onboarding
personas: [P-001]
epic: "Onboarding & Identity"
priority: must-have
complexity: medium
tags: [agents, templates, onboarding, first-run]
---

# US-004: Add First Agents from Templates During Onboarding

## User Story

**As a** solo staff engineer setting up my first project
**I want to** pick one or two starter agents from a gallery of pre-built templates (e.g. "Planner," "Reviewer," "Coder") instead of writing an identity/profile prompt from scratch
**So that** my project has working agents I can immediately @-mention, with the option to customize their versioned profile later

## Acceptance Criteria

- **Given** I have just created my first project (from [[US-002]]) and have zero agents
  **When** the onboarding flow reaches the "add agents" step
  **Then** I see a gallery of role-based agent templates, each showing handle, name, purpose, and default model tier

- **Given** I select one or more templates and confirm
  **When** the confirmation completes
  **Then** a persistent Agent entity (with an initial version-1 identity/profile prompt) and its corresponding project GenServer are created for each selection, and each agent appears as a member of the project's default channel

- **Given** I select a template
  **When** I preview it before confirming
  **Then** I can see and lightly edit the handle and display name (uniqueness enforced within the project) before the agent is instantiated, without needing to touch the full profile prompt editor

- **Given** I skip the "add agents" step entirely
  **When** onboarding completes
  **Then** the project is left with zero agents and a persistent banner/prompt in the channel view offers to resume template selection later

## Notes
Deep agent-identity authoring (full profile prompt versioning, cognition table tuning) is [[P-002]]'s domain and out of scope here — this story only covers instantiating from a template during first-run. Each created agent still gets a real versioned content row for its profile, per the platform's versioned-content mechanic, even though the onboarding UI hides that detail.
