---
id: US-124
title: "Enforce handle change cooldown and history limit"
slug: handle-change-cooldown
personas: [P-010]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, handle, abuse-prevention]
---

# US-124: Enforce Handle Change Cooldown And History Limit

## User Story

**As a** skeptical switcher
**I want to** be limited on how often I can change my handle
**So that** handles stay trustworthy and aren't churned to dodge accountability

## Acceptance Criteria

- **Given** I changed my handle recently
  **When** I try to change it again before the cooldown elapses
  **Then** the change is blocked and I see when I can next change it

- **Given** I have changed handles multiple times
  **When** the system records the change
  **Then** only a limited history is retained and prior handles are held in reserve for a grace period

## Notes
Cooldown discourages handle-squatting and reduces confusion for mutuals.
