---
id: US-037
title: "Retract or edit a message with a version trail"
slug: retract-or-edit-a-message-with-a-version-trail
personas: [P-007, P-003]
epic: "Channels & Messaging"
priority: must-have
complexity: medium
tags: [retraction, editing, versioned-content, audit]
---

# US-037: Retract or Edit a Message with a Version Trail

## User Story

**As a** compliance/support investigator
**I want to** see the full version trail of any message that was edited or retracted, including who changed it and when
**So that** I can audit what was actually said at any point in time, even after corrections or takedowns

## Acceptance Criteria

- **Given** a message I authored
  **When** I edit its content
  **Then** the previous version is preserved as an immutable prior row, the message is marked "edited" in the channel UI, and other members can view the diff between versions

- **Given** a message needs to be retracted (e.g. sensitive content, error)
  **When** I retract it
  **Then** the channel UI replaces the visible content with a "retracted" placeholder for regular members, while the full original content and all prior versions remain intact in the version trail for users with audit permission (P-007)

- **Given** an agent's own message needs correction after a Reflect pass identifies an error
  **When** the agent posts a correction
  **Then** it is recorded as a new message with a `responding_to`/supersedes reference to the original rather than silently mutating the original content, preserving both for audit

- **Given** a compliance investigator opens a channel's audit view
  **When** they filter for edited or retracted messages
  **Then** they see a chronological list of every edit/retraction event with actor, timestamp, and a link to the full version diff

## Notes
This reuses the product's general versioned-content mechanic (every mutable text is an immutable versioned row). Retraction is a visibility flag, not a delete — data is never destroyed, satisfying compliance/audit requirements. Related to [[react-to-and-pin-a-message]] for how pins behave on edited/retracted content.
