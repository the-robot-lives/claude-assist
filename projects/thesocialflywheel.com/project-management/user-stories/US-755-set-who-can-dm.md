---
id: US-755
title: "Set Who Can DM"
slug: set-who-can-dm
personas: [P-004]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [privacy, dm, messaging, safety]
---

# US-755: Set Who Can DM

## User Story

**As a** cautious newcomer
**I want to** restrict who can send me direct messages
**So that** I am not overwhelmed by strangers before I feel comfortable.

## Acceptance Criteria

- **Given** I am on Privacy Settings
  **When** I choose "Mutuals only" for DM permissions
  **Then** users who are not my mutual connections cannot initiate a DM thread with me.

## Notes
Non-mutuals who attempt to message a restricted user see a notice that DMs are limited, not a blank failure.
