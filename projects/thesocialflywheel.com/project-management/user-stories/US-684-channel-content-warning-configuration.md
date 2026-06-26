---
id: US-684
title: "Channel Content Warning Configuration"
slug: channel-content-warning-configuration
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: low
tags: [moderation, content-warnings, channel-settings]
---

# US-684: Channel Content Warning Configuration

## User Story

**As a** channel owner running a community that discusses sensitive but legal topics
**I want to** mark my channel as requiring a content warning acknowledgment
**So that** members self-select in knowingly and the platform is not liable for surprising unsuspecting users

## Acceptance Criteria

- **Given** I open Channel Settings > Content Warning
  **When** I enable the content warning and select a category (Mature Themes, Graphic Discussion, Strong Language, Spoilers)
  **Then** the channel is flagged in discovery results with the appropriate label and new members must tap "I understand" before their first visit

- **Given** a content warning is active
  **When** an existing member who joined before the warning was added visits the channel
  **Then** they are shown the warning and must acknowledge it once before continuing

- **Given** I remove the content warning
  **When** the setting is saved
  **Then** the channel label is removed from discovery immediately and no further acknowledgment prompts are shown

## Notes
Content warnings are not a substitute for moderation; channels flagged for content warnings are still subject to all platform rules.
