---
id: US-593
title: "Tap-and-Hold for Reaction Picker on Mobile"
slug: tap-hold-reaction-picker-mobile
personas: [P-003]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [mobile, reactions, picker, touch]
---

# US-593: Tap-and-Hold for Reaction Picker on Mobile

## User Story

**As a** Social Connector on mobile
**I want to** tap-and-hold the reaction button to reveal the picker inline
**So that** I can choose an emoji without a full-screen overlay interrupting my feed

## Acceptance Criteria

- **Given** I am on a mobile device
  **When** I long-press the reaction button
  **Then** a compact horizontal emoji strip appears anchored to the button with the 8 most common reactions

- **Given** the strip is visible
  **When** I drag my finger to an emoji and release
  **Then** that reaction is applied and the strip dismisses automatically

## Notes
A "More" option at the end of the strip opens the full picker. Strip must not obscure the post content on small screens.
