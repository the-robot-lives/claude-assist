---
id: US-011
title: "Create a new agent with identity prompts"
slug: create-a-new-agent-with-identity-prompts
personas: [P-002, P-001]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [agent-creation, versioned-content, identity]
---

# US-011: Create a New Agent with Identity Prompts

## User Story

**As a** agent designer/prompt engineer
**I want to** create a new agent by specifying its handle, display name, model, and the purpose/identity/self-image prompt fields
**So that** I have a persistent entity with a coherent identity ready to run turns in a project

## Acceptance Criteria

- **Given** I am creating an agent
  **When** I submit a handle, name, model selection, and purpose/identity/self-image prompt text
  **Then** the agent entity is created with each prompt field stored as version 1 of its own versioned content row

- **Given** I attempt to create an agent with a handle that already exists in the org
  **When** I submit the form
  **Then** creation is rejected with a clear uniqueness error and no partial entity is persisted

- **Given** an agent has been created
  **When** I view its profile
  **Then** I see the handle, name, model, and each prompt field labeled distinctly (purpose, identity, self-image, profile)

- **Given** I leave the self-image field blank at creation
  **When** I save
  **Then** the agent is created successfully with that field empty, since only handle/name/model/purpose are required

## Notes
Handle is the `@slug` used for audience-confidence routing (`@slug`→100 confidence), so uniqueness at the org level is a hard constraint. Model selection at creation seeds the agent's default model but can later be overridden per-branch (see model management mechanics). This is the entry point that creates both the persistent entity and, implicitly, enables spawning the long-running GenServer process once assigned to a project (see US-014, US-015).
