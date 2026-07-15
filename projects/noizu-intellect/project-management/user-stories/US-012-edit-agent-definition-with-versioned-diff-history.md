---
id: US-012
title: "Edit agent definition with versioned diff history"
slug: edit-agent-definition-with-versioned-diff-history
personas: [P-002, P-007]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [versioned-content, prompt-editing, audit]
---

# US-012: Edit Agent Definition with Versioned Diff History

## User Story

**As a** agent designer/prompt engineer
**I want to** edit an agent's purpose, identity, self-image, or profile prompt and see a diff against the prior version
**So that** every change to the agent's persona is auditable and I can understand exactly what shifted between versions

## Acceptance Criteria

- **Given** an agent has an existing identity prompt at version 3
  **When** I edit and save the identity field with new text
  **Then** a new immutable version 4 row is created, version 3 is preserved unchanged, and the agent now runs against version 4

- **Given** an agent has multiple prompt versions across its fields
  **When** I open the version history view for the identity field
  **Then** I see a chronological list of versions with author, timestamp, and a line-level diff between any two selected versions

- **Given** I am mid-edit on a prompt field
  **When** I save with no actual text change
  **Then** no new version is created (no-op diff is suppressed)

- **Given** a compliance reviewer needs to audit an agent's prompt history
  **When** they view the diff history
  **Then** they can see who changed what and when for every versioned field, not just the current state

## Notes
Applies to all versioned prompt fields (purpose, identity, self-image, profile) per the "every mutable text is an immutable versioned row" mechanic. This is a prerequisite for US-013 (rollback) and US-018 (A/B forked comparison). P-007 cares about this for behavior-investigation audits.
