---
id: US-016
title: "Tutorial — Swipe-to-Match Introduction"
slug: tutorial-swipe-to-match-intro
personas: [P-004, P-005, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [tutorial, swipe-to-match, onboarding]
---

# US-016: Tutorial — Swipe-to-Match Introduction

## User Story

**As a** new user
**I want to** a guided walkthrough of the Swipe-to-Match lane
**So that** I know how swiping right affects what I share and when I can see others' content

## Acceptance Criteria

- **Given** I enter the Swipe-to-Match lane for the first time
  **When** the tutorial overlay appears
  **Then** it explains: right-swipe means the other user CAN see my posts; I only see theirs once they reciprocate; reciprocation makes us mutuals.

- **Given** I swipe right on a card during the tutorial demo
  **When** the animation completes
  **Then** a confirmation message reinforces the asymmetric visibility rule.

## Notes
Use a dummy/demo card for the tutorial swipe so no real request is sent. Clearly distinguish one-way vs. mutual visibility with iconography.
