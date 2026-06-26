---
id: US-683
title: "Mod Case Handoff"
slug: mod-case-handoff
personas: [P-007]
epic: "Moderation & Reporting"
priority: could-have
complexity: low
tags: [moderation, workflow, handoff]
---

# US-683: Mod Case Handoff

## User Story

**As a** channel moderator who is stepping away mid-investigation
**I want to** reassign my claimed report cases to another mod with a hand-off note
**So that** open cases are not stalled while I am offline

## Acceptance Criteria

- **Given** I have one or more cases in "In Review" status assigned to me
  **When** I select "Reassign" and choose a target mod from the channel's mod team
  **Then** the case ownership transfers to that mod, my hand-off note is appended to the case, and the new assignee receives a notification

- **Given** I go offline without reassigning
  **When** my cases have been in "In Review" status for more than 24 hours with no activity
  **Then** a staleness alert is shown to the channel owner so they can manually reassign

## Notes
Hand-off notes are internal-only and not visible to reporters or reported users.
