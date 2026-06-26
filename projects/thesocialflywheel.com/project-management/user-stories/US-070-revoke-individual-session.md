---
id: US-070
title: "Revoke Individual Session"
slug: revoke-individual-session
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [session-management, revoke, security]
---

# US-070: Revoke Individual Session

## User Story

**As a** skeptical switcher
**I want to** revoke a single specific session from my device list
**So that** I can remove access for a device without logging out everywhere

## Acceptance Criteria

- **Given** I am viewing my active sessions list
  **When** I click "Revoke" on a non-current session and confirm
  **Then** that session is invalidated and removed from the list within 5 seconds

- **Given** I attempt to revoke my current session
  **When** I click "Revoke"
  **Then** I am warned that this will log me out of the current device and prompted to confirm
