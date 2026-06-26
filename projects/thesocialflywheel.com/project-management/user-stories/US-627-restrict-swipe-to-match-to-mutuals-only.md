---
id: US-627
title: "Restrict Swipe-to-Match to Mutuals Only"
slug: restrict-swipe-to-match-to-mutuals-only
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, matching, privacy]
---

# US-627: Restrict Swipe-to-Match to Mutuals Only

## User Story

**As a** cautious newcomer
**I want to** limit who can see me in the Swipe-to-Match lane to my existing mutuals only
**So that** strangers outside my network cannot initiate matching with me

## Acceptance Criteria

- **Given** I set Swipe-to-Match visibility to "Mutuals only" in Privacy Settings
  **When** a user outside my mutual graph opens Swipe-to-Match
  **Then** my profile does not appear in their swipe deck

- **Given** the setting is active
  **When** a direct mutual opens Swipe-to-Match
  **Then** my profile may still appear for them

## Notes
Default setting for new accounts is "Mutuals only" to protect cautious newcomers (US-633).
