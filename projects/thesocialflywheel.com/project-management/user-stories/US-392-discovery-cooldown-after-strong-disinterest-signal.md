---
id: US-392
title: "Discovery Cooldown After Strong Disinterest Signal"
slug: discovery-cooldown-after-strong-disinterest-signal
personas: [P-005]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, tuning, cooldown]
---

# US-392: Discovery Cooldown After Strong Disinterest Signal

## User Story

**As a** Debate Seeker
**I want to** have the discovery engine apply an automatic cooldown on a topic cluster after I dislike multiple items from it in quick succession
**So that** I am not repeatedly shown content I have clearly rejected before I have a chance to explicitly exclude it

## Acceptance Criteria

- **Given** I dislike three or more discovery items from the same topic cluster within a single feed session
  **When** the engine processes my signals
  **Then** that topic cluster is placed in a 14-day cooldown period and does not appear in discovery during that window

- **Given** a topic is in cooldown
  **When** the cooldown period expires
  **Then** the topic returns to normal eligibility unless I have permanently excluded it

## Notes
Cooldown is distinct from permanent exclusion; it is automatic and temporary. Users see no explicit UI for cooldowns but can view and override them from Discovery Settings.
