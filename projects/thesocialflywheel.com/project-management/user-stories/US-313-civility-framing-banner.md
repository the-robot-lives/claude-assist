---
id: US-313
title: "Civility Framing Banner in Opposing-View Lane"
slug: civility-framing-banner
personas: [P-001]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, civility, framing, onboarding]
---

# US-313: Civility Framing Banner in Opposing-View Lane

## User Story

**As a** bridge-builder
**I want to** see a concise civility framing message at the top of the Opposing-Views Lane
**So that** the purpose and expected norms are reinforced each time I enter the lane

## Acceptance Criteria

- **Given** I open the Opposing-Views Lane
  **When** the lane renders
  **Then** a dismissible banner reads "You're seeing views that differ from yours on topics you both care about. Posts here are read-only."

- **Given** I dismiss the banner
  **When** I reopen the lane in the same session
  **Then** the banner does not reappear until my next session

## Notes
Banner must not push lane content below the fold on mobile. Use a compact single-line design.
