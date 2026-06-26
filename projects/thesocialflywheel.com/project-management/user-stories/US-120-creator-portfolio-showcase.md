---
id: US-120
title: "Showcase a creator portfolio on my profile"
slug: creator-portfolio-showcase
personas: [P-009]
epic: "Profile & Identity"
priority: should-have
complexity: high
tags: [profile, creator, showcase]
---

# US-120: Showcase A Creator Portfolio On My Profile

## User Story

**As a** creator
**I want to** add a portfolio/showcase section to my profile
**So that** others can see my work and decide to connect or follow

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I add portfolio items with titles, media, and links
  **Then** the showcase section displays them in my chosen order

- **Given** a viewer sees my profile
  **When** the showcase section is present
  **Then** items respect my field-level visibility settings

- **Given** I remove or reorder a portfolio item
  **When** I save
  **Then** the showcase updates accordingly for subsequent viewers

## Notes
Showcase visibility inherits the per-field controls from US-112 where set.
