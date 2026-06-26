---
id: US-038
title: "First Mutual Connection Made"
slug: first-mutual-connection-made
personas: [P-004, P-003, P-001]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [mutuals, first-connection, milestone, onboarding]
---

# US-038: First Mutual Connection Made

## User Story

**As a** new user
**I want to** a celebratory moment when my first mutual connection is established
**So that** I understand the significance of the moots graph and feel encouraged to keep growing it

## Acceptance Criteria

- **Given** I send a mutual request and the other user accepts
  **When** the acceptance notification arrives
  **Then** a brief in-app toast explains "You and @handle are now moots — their posts will appear in your Mutuals lane."

- **Given** the other user's request arrives and I accept it
  **When** confirmed
  **Then** the same celebration toast fires and the Mutuals lane updates in real time.

## Notes
Toast should be non-blocking and auto-dismiss in 5 s. Also update the onboarding checklist to mark "Find your first moot" complete.
