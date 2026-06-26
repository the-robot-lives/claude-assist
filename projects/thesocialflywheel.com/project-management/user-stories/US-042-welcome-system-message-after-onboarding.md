---
id: US-042
title: "Welcome System Message After Onboarding"
slug: welcome-system-message-after-onboarding
personas: [P-004, P-010, P-006]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [welcome, system-message, onboarding, UX]
---

# US-042: Welcome System Message After Onboarding

## User Story

**As a** newly onboarded user
**I want to** receive a welcome notification from Flywheel that summarises what I set up and what to explore next
**So that** I feel oriented on my first real visit

## Acceptance Criteria

- **Given** I complete the mandatory onboarding steps
  **When** I land on the home screen for the first time
  **Then** an in-app notification from "Flywheel Team" summarises my interests and suggests three channels to visit.

- **Given** the welcome notification is tapped
  **When** it opens
  **Then** I see a full-screen card with my interest summary and CTA buttons ("Explore channels", "Find moots", "Set up profile").

## Notes
Welcome message is sent once per account, immediately after onboarding completes. It should not constitute a marketing message (no promotions). Localise for user's preferred language.
