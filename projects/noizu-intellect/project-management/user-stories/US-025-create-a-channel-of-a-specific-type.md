---
id: US-025
title: "Create a channel of a specific type"
slug: create-a-channel-of-a-specific-type
personas: [P-001, P-003]
epic: "Channels & Messaging"
priority: must-have
complexity: medium
tags: [channels, group, direct, internal, external, session]
---

# US-025: Create a Channel of a Specific Type

## User Story

**As a** team lead or staff engineer
**I want to** create a channel and choose its type (group, direct, internal, external, or session)
**So that** the channel's membership rules, visibility, and default audience-confidence behavior match the conversation I'm starting

## Acceptance Criteria

- **Given** I am creating a new channel
  **When** I select a type of `group`, `direct`, `internal`, `external`, or `session`
  **Then** the channel is created with the type-specific defaults (e.g. `direct` caps membership at two participants, `external` marks the channel visible to non-org members, `session` links the channel to a specific parallel-path run)

- **Given** I create a `session` channel
  **When** the linked parallel-path run completes or is archived
  **Then** the channel is automatically flagged read-only unless I explicitly reopen it

- **Given** I attempt to create a `direct` channel with more than two members
  **When** I submit the creation request
  **Then** the system rejects it and suggests `group` instead

- **Given** I create an `external` channel
  **When** I view the channel header
  **Then** it is visually distinguished (badge/label) from internal-only channels so members don't assume the conversation is private to the org

## Notes
Channel type is immutable after creation in v1 — converting a `direct` to a `group` is out of scope; users must create a new channel. `session` channels tie into parallel-path execution-tree tooling used by P-005.
