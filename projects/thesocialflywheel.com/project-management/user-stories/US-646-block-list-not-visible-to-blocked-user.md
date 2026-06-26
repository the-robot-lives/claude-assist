---
id: US-646
title: "Block List Not Visible to Blocked User"
slug: block-list-not-visible-to-blocked-user
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, privacy, blocking]
---

# US-646: Block List Not Visible to Blocked User

## User Story

**As a** bridge-builder
**I want to** know that a person I block cannot discover they are on my block list
**So that** the safety action does not create a social confrontation or expose my intentions

## Acceptance Criteria

- **Given** I have blocked User X
  **When** User X uses any API or UI feature to enumerate my connections or safety settings
  **Then** they receive no indication that they are blocked by me

- **Given** User X sends me a direct message after being blocked
  **When** the message is sent
  **Then** from User X's side it appears to send normally; delivery is silently dropped

## Notes
Silent drop on DMs avoids tipping off the blocked user; this is the standard privacy pattern.
