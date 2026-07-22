---
id: US-013
title: "Roll back an agent prompt to a prior version"
slug: roll-back-an-agent-prompt-to-a-prior-version
personas: [P-002]
epic: "Agents & Cognition"
priority: must-have
complexity: low
tags: [versioned-content, rollback, prompt-editing]
---

# US-013: Roll Back an Agent Prompt to a Prior Version

## User Story

**As a** agent designer/prompt engineer
**I want to** roll back one of an agent's prompt fields to a specific prior version
**So that** I can undo a regression in agent behavior without hand-retyping the old text

## Acceptance Criteria

- **Given** an agent's identity prompt is at version 5 and version 3 performed better
  **When** I select "roll back to version 3" from the diff history view
  **Then** a new version 6 is created whose content matches version 3 verbatim, and the agent now runs against version 6

- **Given** I roll back a prompt field
  **When** I view the version history afterward
  **Then** version 6 is clearly annotated as "rolled back from v3" so the lineage stays legible in the audit trail

- **Given** a rollback is applied while the agent's process is actively running a turn
  **When** the current turn completes
  **Then** the next turn picks up the rolled-back version; the in-flight turn is not interrupted mid-pass

## Notes
Rollback creates a new version rather than deleting history — this preserves the immutable-versioned-row guarantee from US-012 and keeps compliance audits (P-007) intact. Distinct from A/B forked comparison (US-018), which runs two versions concurrently rather than replacing the live one.
