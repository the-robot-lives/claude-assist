---
id: US-662
title: "Channel Rules Configuration"
slug: channel-rules-configuration
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, channel-rules]
---

# US-662: Channel Rules Configuration

## User Story

**As a** channel owner
**I want to** compose and publish a set of named channel rules
**So that** members know the expected behaviour and mods can cite specific rules when taking action

## Acceptance Criteria

- **Given** I open Channel Settings > Rules
  **When** I add a rule with a short title and description (up to 500 characters)
  **Then** I can save up to 10 rules and reorder them by drag-and-drop

- **Given** channel rules exist
  **When** a new member joins the channel
  **Then** they are shown the rules list and must acknowledge before their first post is allowed

- **Given** rules are published
  **When** a mod issues a warning, timeout, or ban
  **Then** the action form includes a "Rule violated" dropdown pre-populated with the channel's rule titles

## Notes
Rule titles must be unique within a channel and cannot be empty; the platform provides default starter rules for new channels.
