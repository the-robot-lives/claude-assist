---
id: US-859
title: "Live Region for Why-Am-I-Seeing-This Context"
slug: live-region-why-seeing
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [live-regions, screen-reader, discovery, wcag-2.2]
---

# US-859: Live Region for Why-Am-I-Seeing-This Context

## User Story

**As a** screen-reader user
**I want to** have the "why am I seeing this" explanation read aloud when I request it
**So that** I understand feed curation without relying on a tooltip or popover

## Acceptance Criteria

- **Given** a Discovery or Opposing-Views post
  **When** I press the "Why" button
  **Then** a live region announces the full explanation text

- **Given** the explanation panel opens
  **When** screen reader focus enters it
  **Then** focus lands on the explanation heading, not the close button

- **Given** I dismiss the explanation
  **When** focus returns to the feed
  **Then** focus returns to the post card that triggered the action

## Notes

Avoid relying solely on a tooltip (which has poor SR support) for this explanation. Render it as a proper dialog or disclosure widget so it is reachable without hover.
