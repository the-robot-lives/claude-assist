---
id: US-692
title: "Mod Team Case Notes"
slug: mod-team-case-notes
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: low
tags: [moderation, collaboration, notes]
---

# US-692: Mod Team Case Notes

## User Story

**As a** channel moderator collaborating on a complex report
**I want to** add private notes to a report case visible only to other mods and platform T&S
**So that** my team has shared context and I do not lose important investigation details between sessions

## Acceptance Criteria

- **Given** I am viewing any open report case
  **When** I add a note in the "Internal Notes" panel
  **Then** the note is saved with my display name and timestamp, and is immediately visible to all other mods on this channel and to platform T&S reviewers

- **Given** another mod adds a note to a case I am assigned to
  **When** the note is saved
  **Then** I receive an in-app notification so I can review it before taking action

- **Given** a case is closed
  **When** I view it in the resolved queue
  **Then** all internal notes are preserved on the case record and visible to mods and T&S for future reference

## Notes
Notes are internal-only: they must never appear in any user-facing communication, notification, or appeal record visible to reporters or reported parties.
